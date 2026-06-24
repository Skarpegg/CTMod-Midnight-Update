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
	function module.frame ()
		local optionsFrameList = module:framesInit()

		-- helper funcs
		local function optionsAddFrame (offset, size, details, data) module:framesAddFrame(optionsFrameList, offset, size, details, data) end
		local function optionsAddObject (offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details) end
		local function optionsAddScript (name, func) module:framesAddScript(optionsFrameList, name, func) end
		local function optionsAddTooltip (text) module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL) end) end
		local function optionsBeginFrame (offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data) end
		local function optionsEndFrame () module:framesEndFrame(optionsFrameList) end
		local function optionsAddFromTemplate (offset, size, details, template) module:framesAddFromTemplate(optionsFrameList, offset, size, details, template) end

		local textColor0 = "#1.0:1.0:1.0";
		local textColor1 = "#0.9:0.9:0.9";
		local textColor2 = "#0.7:0.7:0.7";
		local textColor3 = "#0.9:0.72:0.0";
		local xoffset, yoffset;

		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#CT_BarMod is currently disabled." .. textColor2 .. ":l")
		
		return "frame#all", module:framesGetData(optionsFrameList);
	end
	--return
end

--------------------------------------------
-- Local Copies

local format = format;
local gsub = gsub;
local ipairs = ipairs;
local pairs = pairs;
local print = print;
local select = select;
local strfind = strfind;
local strsub = strsub;
local tonumber = tonumber;
local tostring = tostring;
local type = type;
local unpack = unpack;
local InCombatLockdown = InCombatLockdown;
local IsShiftKeyDown = IsShiftKeyDown;
local UnitClass = UnitClass;

local groupList = module.groupList;

-- End Local Copies
--------------------------------------------

local theOptionsFrame;

-------------------------------------------
-- Miscellaneous

local preventLoop;
module.updateOptionFromOutside = function(optName, value)
	if (preventLoop) then
		return;
	end

	if optName == "disableDefaultActionBar"
		or optName == "disableDragonflightActionBarChangedDate"
		or optName == "disableDragonflightActionBar"
	then
		module:setOption(optName, value)
	end
end

--------------------------------------------
-- Options Updater

local function updateGroups()
	-- Apply group option values to the groups.
	local groupId;
	for num, group in pairs(groupList) do
		groupId = group.groupId;

		group:update("orientation", module:getOption("orientation" .. groupId) or "ACROSS");
		group:update("barFlipHorizontal", not not module:getOption("barFlipHorizontal" .. groupId));
		group:update("barFlipVertical", not not module:getOption("barFlipVertical" .. groupId));

		group:update("barNumToShow", module:getOption("barNumToShow" .. groupId) or 12);  -- do before "barColumns"
		group:update("barColumns", module:getOption("barColumns" .. groupId) or 12);

		group:update("barSpacing", module:getOption("barSpacing" .. groupId) or 6);

		group:update("barScale", module:getOption("barScale" .. groupId) or 1);

		group:update("barMouseover", module:getOption("barMouseover" .. groupId) == true);  -- do before "barOpacity"
		group:update("barFaded", module:getOption("barFaded" .. groupId) or 0);  -- do before "barOpacity"
		group:update("barFadedCombat", module:getOption("barFadedCombat" .. groupId) or module:getOption("barFaded" .. groupId) or 0);  -- do before "barOpacity"
		group:update("barOpacity", module:getOption("barOpacity" .. groupId) or 1);

		group:update("showGroup", module:getOption("showGroup" .. groupId) ~= false);

--		group:update("barHideInPetBattle", module:getOption("barHideInPetBattle" .. groupId));
--		group:update("barHideInVehicle", module:getOption("barHideInVehicle" .. groupId));
--		group:update("barHideInOverride", module:getOption("barHideInOverride" .. groupId));
--		group:update("barHideInCombat", module:getOption("barHideInCombat" .. groupId));
--		group:update("barHideNotCombat", module:getOption("barHideNotCombat" .. groupId));
--		group:update("barCondition", module:getOption("barCondition" .. groupId) or "");
--		group:update("barVisibility", module:getOption("barVisibility" .. groupId) or 1);

--		group:update("pageAltKey", module:getOption("pageAltKey" .. groupId) or 1);
--		group:update("pageCtrlKey", module:getOption("pageCtrlKey" .. groupId) or 1);
--		group:update("pageShiftKey", module:getOption("pageShiftKey" .. groupId) or 1);
--		group:update("pageCondition", module:getOption("pageCondition" .. groupId) or "");
--		group:update("barPaging", module:getOption("barPaging" .. groupId) or 1);
	end
end

----------
-- Reset group positions

local function resetGroupPositions()
	-- Reset each group to its default position.
	if (InCombatLockdown()) then
		module:print("Bar positions cannot be reset while in combat.");
	else
		for key, value in pairs(groupList) do
			value:resetPosition();
		end
		CT_BarMod_Shift_ResetPositions();
	end
end

----------
-- Update click direction of buttons.

local function updateClickDirection()
	if (InCombatLockdown()) then
		module.needUpdateClickDirection = true;
		return;
	end

	--local down = not not module:getOption("clickDirection");
	--local click = not not module:getOption("clickIncluded");
	
	local GetCVar = GetCVar or C_CVar.GetCVar;
	local keydown = GetCVar("ActionButtonUseKeyDown") == "1";		-- 1 is the default value, meaning activate abilities when you press DOWN
	local mousedown = module:getOption("onMouseDown");			-- defaults to false, and is ignored if keydown was 0

	for gkey, group in pairs(groupList) do
		local objects = group.objects;
		if ( objects ) then
			for bkey, object in ipairs(objects) do
				--object:setClickDirection(down, click);
				object:setClickDirection(keydown, mousedown);
			end
		end
	end

	module.needUpdateClickDirection = false;
end

----------
-- Cooldown font

local fontTypeList = {
	["Arial Narrow"] = "Fonts\\ARIALN.TTF",
	["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
	["Morpheus"] = "Fonts\\MORPHEUS.ttf",
	["Skurri"] = "Fonts\\skurri.ttf",
};
-- In the past, we were assigning "MONOCHROME" to the "Plain" style.
-- However, in WoW 5.0.5 using "MONOCHROME" can cause corrupted text, nothing to be displayed, or the game can crash.
-- Using an empty string (or nil, or almost any other string) will display plain looking text, so we'll use that instead.
-- According to http://wowprogramming.com/docs/widgets/FontInstance/SetFont the "MONOCHROME" property just disables antialiasing.
local fontStyleList = {
	["Outline"] = "OUTLINE",
	["Plain"] = "",
	["Thick Outline"] = "THICKOUTLINE",
};

local fontDefaultTypeNum;
local fontDefaultTypeName = "Friz Quadrata TT";
local fontDefaultStyleNum;
local fontDefaultStyleName = "Outline";
local fontDefaultSize = 16;
local fontDefaultColor = {1, 0.82, 0, 1};

local fontCache = {};
local fontTypeListSorted = {};
local fontStyleListSorted = {};

for name, file in pairs(fontTypeList) do
	tinsert(fontTypeListSorted, name);
end
sort(fontTypeListSorted);
fontDefaultTypeNum = 1;
for i = 1, #fontTypeListSorted do
	if (fontTypeListSorted[i] == fontDefaultTypeName) then
		fontDefaultTypeNum = i;
		break;
	end
end

for name, flags in pairs(fontStyleList) do
	tinsert(fontStyleListSorted, name);
end
sort(fontStyleListSorted);
fontDefaultStyleNum = 1;
for i = 1, #fontStyleListSorted do
	if (fontStyleListSorted[i] == fontDefaultStyleName) then
		fontDefaultStyleNum = i;
		break;
	end
end

local function getFont(file, size, flags)
	local name, font;
	if (not file) then
		file = "Fonts\\FRIZQT__.TTF";
	end
	if (not size) then
		size = fontDefaultSize;
	end
	if (not flags) then
		local styleName = fontStyleListSorted[fontDefaultStyleNum];
		flags = fontStyleList[styleName];
	end
	name = "CT_BarMod_Font_" .. file .. size .. flags;
	if (not fontCache[name]) then
		font = CreateFont(name);
		font:SetFont(file, size, flags);
		font:SetJustifyH("CENTER");
		font:SetJustifyV("MIDDLE");
		-- font:SetShadowColor(0, 0, 0, 1);
		-- font:SetShadowOffset(1, -1);
		-- font:SetSpacing(0);
		font:SetTextColor(unpack(fontDefaultColor));
		fontCache[name] = font;
	end
	return name;
end

local function getCooldownFontColor()
	local color = module:getOption("cooldownFontColor");
	if (not color) then
		color = fontDefaultColor;
	end
	return color;
end

local function getCooldownFontSize()
	local size = module:getOption("cooldownFontSize");
	if (not size) then
		size = fontDefaultSize;
	end
	return size;
end

local function getCooldownFontInfo()
	local fontTypeNum, fontTypeName, fontTypeFile;
	fontTypeName = module:getOption("cooldownFontTypeName");
	if (not fontTypeName) then
		fontTypeNum = fontDefaultTypeNum;
	else
		fontTypeNum = 1;
		for i = 1, #fontTypeListSorted do
			if (fontTypeListSorted[i] == fontTypeName) then
				fontTypeNum = i;
				break;
			end
		end
	end
	fontTypeName = fontTypeListSorted[fontTypeNum];
	fontTypeFile = fontTypeList[fontTypeName];
	return fontTypeNum, fontTypeName, fontTypeFile;
end

local function getCooldownFontStyle()
	local fontStyleNum, fontStyleName, fontStyleFlags;
	fontStyleName = module:getOption("cooldownFontStyleName");
	if (not fontStyleName) then
		fontStyleNum = fontDefaultStyleNum;
	else
		fontStyleNum = 1;
		for i = 1, #fontStyleListSorted do
			if (fontStyleListSorted[i] == fontStyleName) then
				fontStyleNum = i;
				break;
			end
		end
	end
	fontStyleName = fontStyleListSorted[fontStyleNum];
	fontStyleFlags = fontStyleList[fontStyleName];
	return fontStyleNum, fontStyleName, fontStyleFlags;
end

local function updateCooldownFontColor()
	local color = module:getOption("cooldownFontColor");
	if (not color) then
		color = fontDefaultColor;
	end
	CT_BarMod_CooldownFont:SetTextColor(unpack(color));
end

local function updateCooldownFont()
	local fontTypeNum, fontTypeName, fontTypeFile = getCooldownFontInfo();
	local fontSize = getCooldownFontSize();
	local fontStyleNum, fontStyleName, fontStyleFlags = getCooldownFontStyle();
	local fontname = getFont(fontTypeFile, fontSize, fontStyleFlags);
	CT_BarMod_CooldownFont:SetFontObject(fontname);
	updateCooldownFontColor();
end

----------
-- Update other widgets

local function updateWidgets_DisableActionBar()
	local frame = theOptionsFrame;
	if (type(frame) == "table") then
		frame = frame.enablebars;
		local optName = "disableDefaultActionBar";
		local obj = frame[optName];
		obj:SetChecked( module:getOption(optName) );
	end
end

local function updateWidgets_hideExtraBars()
	local frame = theOptionsFrame;
	if (type(frame) == "table") then
		-- If user enables the "hideExtraBar3" option, then hide
		-- the "hideExtraBar4" checkbox.
		frame = frame.bar12options;
		local obj4 = frame.hideExtraBar4;
		local hide3 = not not module:getOption("hideExtraBar3");
		local hide4 = not not module:getOption("hideExtraBar4");
		if (hide3) then
			obj4:SetChecked(true);
			obj4:Disable();
			obj4.text:SetTextColor(0.5, 0.5, 0.5);
		else
			obj4:SetChecked(hide4);
			obj4:Enable();
			obj4.text:SetTextColor(1, 1, 1);
		end
	end
end

----------
-- Update the group widgets

local currentEditGroup = module.GroupNumToId(1);  -- default to group number 1
local groupFrame;

local function updateGroupWidgets_Visibility(groupId)
	if ( not groupFrame ) then
		return;
	end
	if (groupId == nil or groupId ~= currentEditGroup) then
		return;
	end

	local basic, advanced;
	local value = module:getOption("barVisibility" .. groupId) or 1;

	if (value == 2) then
		-- Advanced conditions
		advanced = true;
	else
		-- Basic conditions
		basic = true;
	end

	if (basic) then
		-- Enable basic options
		groupFrame.visBasic:SetChecked(1);
	else
		-- Disable basic options
		groupFrame.visBasic:SetChecked(nil);
	end

	if (advanced) then
		-- Enable advanced options
		groupFrame.visAdvanced:SetChecked(1);
	else
		-- Disable advanced options
		groupFrame.visAdvanced:SetChecked(nil);
	end

	groupFrame.conditionEB:ClearFocus();
	groupFrame.conditionEB:HighlightText(0, 0);
end

local function updateGroupWidgets_Paging(groupId)
	if ( not groupFrame ) then
		return;
	end
	if (groupId == nil or groupId ~= currentEditGroup) then
		return;
	end

	local basic, advanced;
	local value = module:getOption("barPaging" .. groupId) or 1;

	if (value == 2) then
		-- Advanced conditions
		advanced = true;
	else
		-- Basic conditions
		basic = true;
	end

	if (basic) then
		-- Enable basic options
		groupFrame.pageBasic:SetChecked(1);
	else
		-- Disable basic options
		groupFrame.pageBasic:SetChecked(nil);
	end

	if (advanced) then
		-- Enable advanced options
		groupFrame.pageAdvanced:SetChecked(1);
	else
		-- Disable advanced options
		groupFrame.pageAdvanced:SetChecked(nil);
	end

	groupFrame.pageEB:ClearFocus();
	groupFrame.pageEB:HighlightText(0, 0);
end

local function updateGroupWidgets_Columns(groupId)
	if ( not groupFrame ) then
		return;
	end
	if (groupId == nil or groupId ~= currentEditGroup) then
		return;
	end

	local slider = groupFrame.columns;
	local title, low, high = slider.Text, slider.Low, slider.High

	-- Save the current value of the "barColumns" option before we change the upper limit.
	local barColumns = module:getOption("barColumns" .. groupId) or 12;

	-- Change the slider's max value if necessary.
	-- This may cause CT_Library to change the "barColumns" option.
	-- We want the upper limit of the "barColumns" slider to be the number
	-- of buttons that the user wants to show on the bar. This will dictate
	-- what row x column arrangements are possible.

	local minValue, maxValue = slider:GetMinMaxValues();
	local barNumToShow = module:getOption("barNumToShow" .. groupId) or 12;
	if (maxValue ~= barNumToShow) then
		slider:SetMinMaxValues(minValue, barNumToShow);
		high:SetText(barNumToShow);
	end

	-- Change the slider's current value.
	-- This may cause CT_Libray to change the "barColumns" option.
	--
	-- Even though changing the upper limit may have altered the "barColumns" option value,
	-- we want to use the value we saved prior to setting the upper limit, rather than using
	-- the value that resulted from changing the slider's upper limit.
	--
	-- When we are navigating from one group to the next in the options window, if the previously shown
	-- group's upper limit is different than the current group's upper limit, changing the upper
	-- could cause an unwanted change to the current group's "barColumns" option.
	--
	-- To avoid this issue we saved the "barColumns" option value before we changed the upper limit.
	-- Now, we'll assign that saved value to the slider.
	--
	-- If the saved value is beyond the upper limit, then changing the slider's value will force the
	-- value to be set to the upper limit.
	--
	-- If the saved value is within the limits, then we will have restored the value we want.
	--
	-- In either case, if the slider values is different then it will cause the "barColumns" option
	-- to be changed. Unlike the upper limit, it does not matter if the previously shown group's slider
	-- had a different value than the current group.

	local value = slider:GetValue()
	if (value ~= barColumns) then
		slider:SetValue(barColumns);
	end

	-- Update the text shown above the slider.
	local group = groupList[ module.GroupIdToNum(groupId) ];
	if ( group ) then
		if (module:getOption("orientation" .. groupId) == "ACROSS") then
			title:SetText(group.numColumns .. " x " .. group.numRows);  -- columns x rows
		else
			title:SetText(group.numRows .. " x " .. group.numColumns);  -- columns x rows
		end
	end
end

local function updateGroupWidgets_Orientation(groupId)
	if ( not groupFrame ) then
		return;
	end
	if (groupId == nil or groupId ~= currentEditGroup) then
		return;
	end
	local value;
	UIDropDownMenu_Initialize(CT_BarModDropOrientation, CT_BarModDropOrientation.initialize);
	value = module:getOption("orientation" .. groupId) or "ACROSS";
	if (value == "DOWN") then
		value = 2;
	else
		value = 1; -- "ACROSS"
	end
	UIDropDownMenu_SetSelectedValue(CT_BarModDropOrientation, value);
end

local function updateGroupWidgets_ShowGroup(groupId)
	if ( not theOptionsFrame ) then
		return;
	end
	for num = 1, module.maxBarNum do
		local groupId = module.GroupNumToId(num);
		local cb = "showGroup" .. groupId;
		local opt = "showGroup" .. groupId;
		local frame = theOptionsFrame.enablebars;
		frame[cb]:SetChecked( module:getOption(opt) ~= false );
	end
end

local function updateGroupWidgets(groupId)
	-- Update UI objects related to the bar that was selected.
	if ( not groupFrame ) then
		return;
	end
	if (not groupId) then
		groupId = currentEditGroup;
	end
	if (groupId == nil or groupId ~= currentEditGroup) then
		return;
	end

	local value;
	local dropdown;

	----------
	-- Select Bar menu
	----------
	dropdown = CT_BarModDropdown2;
	UIDropDownMenu_Initialize(dropdown, dropdown.initialize);
	UIDropDownMenu_SetSelectedValue(dropdown, module.GroupIdToNum(groupId));

	----------
	-- Enable bars
	----------
	updateGroupWidgets_ShowGroup(groupId);

	----------
	-- Appearance
	----------
	groupFrame.scale:SetValue( module:getOption("barScale" .. groupId) or 1 );
	groupFrame.spacing:SetValue( module:getOption("barSpacing" .. groupId) or 6 );
	groupFrame.barNumToShow:SetValue( module:getOption("barNumToShow" .. groupId) or 12 );

	updateGroupWidgets_Orientation(groupId);
	groupFrame.barFlipHorizontal:SetChecked( module:getOption("barFlipHorizontal" .. groupId) );
	groupFrame.barFlipVertical:SetChecked( module:getOption("barFlipVertical" .. groupId) );
	updateGroupWidgets_Columns(groupId);

	----------
	-- Opacity
	----------
	local groupFades =  module:getOption("barMouseover" .. groupId)
	groupFrame.mouseover:SetChecked( groupFades );
	groupFrame.barFaded:SetValue( module:getOption("barFaded" .. groupId) or 0 );
	groupFrame.barFadedCombat:SetValue( module:getOption("barFadedCombat" .. groupId) or module:getOption("barFaded" .. groupId) or 0 );
	groupFrame.barFaded:SetAlpha((groupFades and 1) or 0.5);
	groupFrame.barFadedCombat:SetAlpha((groupFades and 1) or 0.5);
	groupFrame.opacity:SetValue( module:getOption("barOpacity" .. groupId) or 1 );

	----------
	-- Visibility
	----------
	updateGroupWidgets_Visibility(groupId);

	-- Basic conditions
	groupFrame.barHideInPetBattle:SetChecked( module:getOption("barHideInPetBattle" .. groupId) ~= false );
	groupFrame.barHideInVehicle:SetChecked( module:getOption("barHideInVehicle" .. groupId) ~= false );
	groupFrame.barHideInOverride:SetChecked( module:getOption("barHideInOverride" .. groupId) ~= false );
	groupFrame.hideInCombat:SetChecked( module:getOption("barHideInCombat" .. groupId) );
	groupFrame.hideNotCombat:SetChecked( module:getOption("barHideNotCombat" .. groupId) );

	-- Advanced conditions
	groupFrame.conditionEB:SetText( module:getOption("barCondition" .. groupId) or "" );
	groupFrame.visSave:Disable();

	groupFrame.conditionEB.ctUndo = module:getOption("barCondition" .. groupId) or "";
	groupFrame.visUndo:Disable();

	----------
	-- Paging
	----------
	updateGroupWidgets_Paging(groupId);

	-- Basic conditions
	dropdown = CT_BarModDropdown_pageAltKey;
	UIDropDownMenu_Initialize(dropdown, dropdown.initialize);
	UIDropDownMenu_SetSelectedValue(dropdown, module:getOption("pageAltKey" .. groupId) or 1);

	dropdown = CT_BarModDropdown_pageCtrlKey;
	UIDropDownMenu_Initialize(dropdown, dropdown.initialize);
	UIDropDownMenu_SetSelectedValue(dropdown, module:getOption("pageCtrlKey" .. groupId) or 1);

	dropdown = CT_BarModDropdown_pageShiftKey;
	UIDropDownMenu_Initialize(dropdown, dropdown.initialize);
	UIDropDownMenu_SetSelectedValue(dropdown, module:getOption("pageShiftKey" .. groupId) or 1);

	-- Advanced conditions
	groupFrame.pageEB:SetText( module:getOption("pageCondition" .. groupId) or "" );
	groupFrame.pageSave:Disable();

	groupFrame.pageEB.ctUndo = module:getOption("pageCondition" .. groupId) or "";
	groupFrame.pageUndo:Disable();
end

----------
-- Show headers (drag frames)

local function showGroupHeaders_CTBottomBar(self)
	-- If CT_BottomBar is detected then show its bars as well.
	if ( self and CT_BottomBar and CT_BottomBar.show ) then
		-- Call without self parameter to prevent infinite loop.
		CT_BottomBar.show(nil);
	end
end

local function showGroupHeaders(self)
	-- This will show all of the bars drag frames.
	-- It is called when the options window opens.
	module.showingHeaders = 1;  -- options window is open
	for key, obj in pairs(groupList) do
		obj:toggleHeader(true);
	end
	if (not not module:getOption("showCTBottomBar")) then
		showGroupHeaders_CTBottomBar(self);
	end
	updateGroups();
--	module.CT_BarMod_UpdateVisibility();
end

module.show = showGroupHeaders;

----------
-- Hide headers (drag frames)

local function hideGroupHeaders_CTBottomBar(self)
	-- If CT_BottomBar is detected then hide its bars as well.
	if ( self and CT_BottomBar and CT_BottomBar.hide ) then
		-- Call without self parameter to prevent infinite loop.
		CT_BottomBar.hide(nil);
	end
end

local function hideGroupHeaders(self)
	-- This will hide all of the bars.
	-- It is called when the options window closes.
	module.showingHeaders = nil;
	for key, value in pairs(groupList) do
		value:toggleHeader(false);
	end
	if (not not module:getOption("showCTBottomBar")) then
		hideGroupHeaders_CTBottomBar(self);
	end
	updateGroups();
--	module.CT_BarMod_UpdateVisibility();
end

module.hide = hideGroupHeaders;

----------
-- Build condition

local function buildCondition(text)
	-- Convert the user specified text from the multiline editbox
	-- into a single line condition.

	-- Replace line terminators with semicolons.
	-- User should only press enter after typing actions.
	local cond = gsub(text, "\n", ";");

	-- Replace pairs of semicolons with single semicolons.
	-- User might have typed a semicolon after an action, and then pressed enter.
	while (strfind(cond, ";;")) do
		cond = gsub(cond, ";;", ";");
	end

	-- If the final character is a semicolon, then eliminate it.
	if (strsub(cond, #cond, #cond) == ";") then
		cond = strsub(cond, 1, #cond - 1);
	end

	-- Replace the old bonusbar:5 (WoW 4) with the new possessbar (WoW 5)
	-- and change the page number from the old 11 to the new 12.
	-- This doesn't handle the large bonus bars that bonusbar:5 also used to detect,
	-- but those ones are now using a different page number (14, overridebar) anyway.
	cond = gsub(cond, "%[bonusbar:5%] *11", "[possessbar]12");
	cond = gsub(cond, "%[bonusbar:5%]", "[possessbar]");

	return cond;
end

module.buildCondition = buildCondition;

local function buildVisBasicCondition(groupId)
	-- Build the basic condition string.
	local cond;

	local hideInPetBattle = module:getOption("barHideInPetBattle" .. groupId) ~= false;
	local hideInVehicle = module:getOption("barHideInVehicle" .. groupId) ~= false;
	local hideInOverride = module:getOption("barHideInOverride" .. groupId) ~= false;
	local hideInCombat = module:getOption("barHideInCombat" .. groupId);
	local hideNotCombat = module:getOption("barHideNotCombat" .. groupId);

	cond = "";
	if (hideInPetBattle) then
		cond = cond .. "[petbattle]hide; ";
	end
	if (hideInVehicle) then
		cond = cond .. "[vehicleui]hide; ";
	end
	if (hideInOverride) then
		cond = cond .. "[overridebar]hide; ";
	end
	if (hideInCombat) then
		cond = cond .. "[combat]hide; ";
	end
	if (hideNotCombat) then
		cond = cond .. "[nocombat]hide; ";
	end

	if (groupId == module.controlBarId) then
		-- Show if vehicle, override, or possess buttons
		cond = cond .. "[vehicleui] [overridebar] [possessbar]show; hide";
	else
		cond = cond .. "show";
	end

	return cond;
end

local function buildVisAdvancedCondition(groupId)
	return buildCondition(module:getOption("barCondition" .. groupId) or "");
end

----------
-- Group visibility

local function CT_BarMod_UpdateGroupVisibility(groupId)
	if (not InCombatLockdown()) then
		local cond;
		local frame = _G["CT_BarMod_Group" .. groupId];

		if (module:getOption("showGroup" .. groupId) == false) then
			-- Disabled
			UnregisterStateDriver(frame, "visibility");
			frame:Hide();
		else
			local barVisibility = module:getOption("barVisibility" .. groupId) or 1;

			if (barVisibility == 2) then
				-- Advanced conditions
				cond = buildVisAdvancedCondition(groupId);
			else
				-- Basic conditions
				cond = buildVisBasicCondition(groupId);
			end
			RegisterStateDriver(frame, "visibility", cond);
		end
	end
end

local function CT_BarMod_UpdateVisibility()
	for num, group in pairs(groupList) do
		CT_BarMod_UpdateGroupVisibility(group.groupId);
	end
end
module.CT_BarMod_UpdateVisibility = CT_BarMod_UpdateVisibility;


--------------------------------------------
-- Suppress action bars from reappearing when learning abilities

do
	local isSuppressing
	
	function module.suppressActionBarController(enable)
		if (enable) then
			ActionBarController:UnregisterEvent("ACTIONBAR_SHOW_BOTTOMLEFT")
			isSuppressing = true
		elseif (isSuppressing) then
			ActionBarController:RegisterEvent("ACTIONBAR_SHOW_BOTTOMLEFT")
			isSuppressing = false
		end
	end
	
	module.suppressActionBarController(module:getOption("disableIconIntro") ~= false)

	module:regEvent("ACTIONBAR_SHOW_BOTTOMLEFT", function()
		if (isSuppressing) then
			local __, bottomRight, sideRight, sideLeft = GetActionBarToggles()
			SetActionBarToggles(false, bottomRight, sideRight, sideLeft)
		end
	end)

end

--------------------------------------------
-- Silence new-ability frames once dragging spells to custom CT frames

do
	local isControlling

	function module.controlZoneAbilityFrame(enable)
		isControlling = enable
	end
	
	module.controlZoneAbilityFrame(module:getOption("newZoneAbilities") ~= false)
	
	if (ZoneAbilityFrame) then
		hooksecurefunc(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities", function(frame)
			if (isControlling and #frame.previousZoneAbilities == 1 and frame:IsShown() and not InCombatLockdown()) then
				local spellID = frame.previousZoneAbilities[1]["spellID"]
				if (spellID) then
					local actionIDs = C_ActionBar.FindSpellActionButtons(spellID)
					if (actionIDs) then for __, actionID in ipairs(actionIDs) do
						local button = _G["CT_BarModActionButton" .. actionID]
						if (button and button:IsVisible()) then
							frame:Hide()
							return
						end
					end end
				end
			end
		end)
	end
	
	--[[
	if (NPE_LoadUI) then
		local firstTime = true
		hooksecurefunc("NPE_LoadUI", function()
			if (GetTutorialsEnabled() and C_PlayerInfo.IsPlayerNPERestricted() and firstTime) then
				firstTime = false
				hooksecurefunc(NPE_TutorialDragButton, "Show", function(self) 
					if (isSuppressing) then
						C_Timer.After(2, function() NPE_TutorialDragButton.Hide(self) end)
					end
				end)
			end
		end)
	end
	--]]

end

----------
-- Help button tooltips

local function advancedVisTooltip0(self, groupId)
	-- self == the "?" button
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 91);
	GameTooltip:SetText("Visibility conditions");
	GameTooltip:AddLine("Standard macro conditions are used to control the visibility of the selected bar.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe valid actions that you can use with visibility conditions are:", 1, 1, 1, true);
	GameTooltip:AddLine("hide, show", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("\nThe 'hide' action will hide the bar, and the 'show' action will show the bar.", 1, 1, 1, true);
	GameTooltip:AddLine("\nHere's an example that hides the bar when you are in a vehicle or combat, otherwise it shows the bar:", 1, 1, 1, true);
	GameTooltip:AddLine("[vehicleui]hide\n[combat]hide\nshow", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("\nHere's an example that shows the bar when the game's bonus bar page is 1, otherwise it hides the bar:", 1, 1, 1, true);
	GameTooltip:AddLine("[bonusbar:1]show; hide", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("\nThese are the current basic visibility conditions for this bar:", 1, 0.82, 0, true);
	GameTooltip:AddLine(buildVisBasicCondition(groupId), 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("\nShift click this ? button to paste the current basic visibility conditions into the edit window.", 1, 0.82, 0, true);
	GameTooltip:Show();
end

local function advancedPageTooltip0(self, groupId)
	-- self == the "?" button
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 91);
	GameTooltip:SetText("Paging conditions");
	GameTooltip:AddLine("Standard macro conditions are used to control which bar's buttons are shown on the current bar.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe valid actions that you can use with paging conditions are:", 1, 1, 1, true);
	GameTooltip:AddLine("1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("\nThe first 10 paging actions are numbers that represent one of CT_BarMod's first 10 action bars. Each action will cause the buttons from the corresponding bar to be shown on the current bar when the associated condition is true.", 1, 1, 1, true);
	GameTooltip:AddLine("\nAction 11 refers to the page of abilities assigned to multicast bar button slots.", 1, 1, 1, true);
	GameTooltip:AddLine("\nAction 12 refers to the page of abilities assigned to vehicle bar and possess bar button slots.", 1, 1, 1, true);
	GameTooltip:AddLine("\nAction 13 refers to the page of abilities assigned to temporary shapeshift bar button slots.", 1, 1, 1, true);
	GameTooltip:AddLine("\nAction 14 refers to the page of abilities assigned to override bar button slots.", 1, 1, 1, true);
	GameTooltip:AddLine("\nHere's an example that shows the buttons from bar 6 when the alt key is pressed, the buttons from bar 2 when you are in form 1, or the buttons from bar 3 when none of the conditions are true:", 1, 1, 1, true);
	GameTooltip:AddLine("[mod:alt]6; [form:1]2; 3", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("\nThese are the current basic paging conditions for this bar:", 1, 0.82, 0, true);
	GameTooltip:AddLine(module:buildPageBasicCondition(groupId), 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("\nShift click this ? button to paste the current basic paging conditions into the edit window.", 1, 0.82, 0, true);
	GameTooltip:Show();
end

local function advancedTooltip1(self)
	-- self == the "?" button
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 63);
	GameTooltip:SetText("Condition format");
	GameTooltip:AddLine("Each line should contain zero or more macro conditions followed by an action. If you don't specify a condition it defaults to true.", 1, 1, 1, true);
	GameTooltip:AddLine("\nAll conditions must be enclosed in [square brackets]. Within the brackets you can separate multiple conditions using commas (each comma acts like an 'and').", 1, 1, 1, true);
	GameTooltip:AddLine("\nMultiple [conditions] can be placed next to each other. This acts like an 'or' between each pair of brackets.", 1, 1, 1, true);
	GameTooltip:AddLine("\nA semicolon ';' must be used to separate an action from a following [condition] on the same line. You can omit the semicolon if you press enter after the action instead.", 1, 1, 1, true);
	GameTooltip:AddLine("\nIt is ok for a long line to automatically wrap onto the next line. Don't press enter unless you do so after an action.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe game will perform the action that is associated with the first set of true conditions.", 1, 1, 1, true);
--	GameTooltip:AddLine("\nThe actions that you can use for visibility are: hide, show.", 1, 1, 1, true);
--	GameTooltip:AddLine("\nA simple example:\n\n[vehicleui]hide\n[combat]hide\nshow", 1, 1, 1, true);
	GameTooltip:AddLine("\nFor information on macro conditions, refer to sections 12 through 14 at: www.wowpedia.org/Making_a_macro", 1, 1, 1, true);
	GameTooltip:Show();
end

local function advancedTooltip2(self)
	-- self == the "?" button
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 35);
	GameTooltip:SetText("Macro conditions");
	GameTooltip:AddLine("A '/' is used with specific conditions to separate multiple values to test for. The '/' acts like an 'or'.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe letters 'no' can be placed at the start of most condition names to alter the meaning of the condition.", 1, 1, 1, true);
	GameTooltip:AddLine("\n@<unit or name>\nactionbar:1/.../6\nbar:1/.../6\nbonusbar:1/.../4\nchanneling:<spell name>\ncombat\ndead\nequipped:<slot or type or subtype>\nexists\nextrabar\nflyable\nflying\ngroup:party/raid\nform:0/.../n\nharm\nhelp\nindoors\nmod:shift/ctrl/alt\nmodifier:shift/ctrl/alt\nmounted\noverridebar\noutdoors\nparty\npet\npet:<name or type>\npetbattle\npossessbar\nraid\nspec:1/2\nstance:0/1/2/.../n\nstealth\nswimming\ntarget=<unit or name>\nunithasvehicleui\nvehicleui\nworn:<slot or type or subtype>", 1, 1, 1, false);
	GameTooltip:Show();
end

local function advancedTooltip3(self)
	-- self == the "?" button
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 7);
	GameTooltip:SetText("Bar and form conditions");

	GameTooltip:AddLine("The following conditions are true when the corresponding page of the game's main action bar is selected. You can use 'bar' instead of 'actionbar' if you prefer.", 1, 1, 1, true);
	GameTooltip:AddLine("actionbar:1", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("actionbar:2", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("actionbar:3", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("actionbar:4", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("actionbar:5", 0.45, 0.75, 0.95, true);
	GameTooltip:AddLine("actionbar:6", 0.45, 0.75, 0.95, true);

	GameTooltip:AddLine("\nThe following condition is true for druid Cat Form, rogue Stealth and Shadow Dance, and priest Shadow Form.", 1, 1, 1, true);
	GameTooltip:AddLine("bonusbar:1", 0.45, 0.75, 0.95, true);

	GameTooltip:AddLine("\nThe following condition is true for druid Bear Form.", 1, 1, 1, true);
	GameTooltip:AddLine("bonusbar:3", 0.45, 0.75, 0.95, true);

	GameTooltip:AddLine("\nThe following condition is true for druid Moonkin Form.", 1, 1, 1, true);
	GameTooltip:AddLine("bonusbar:4", 0.45, 0.75, 0.95, true);

	GameTooltip:AddLine("\nThe 'form' conditions are similar to the 'bonusbar' conditions, except that the form numbers correspond to the forms that you currently know.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe first form shown on your class bar corresponds to the 'form:1' condition. You can use 'stance' instead of 'form' if you prefer.", 1, 1, 1, true);

	GameTooltip:Show();
end

local function enableBar12Tooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 280, 0);
	GameTooltip:SetText("Bar 12 (Action bar)");
	GameTooltip:AddLine("You can switch between pages using the six 'Action page' key bindings defined in the game's Key Bindings window.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe buttons shown for pages 2 through 6 come from bars 2 through 6.", 1, 1, 1, true);
	GameTooltip:AddLine("\nWhen you are not in a form or stance, the buttons shown for page 1 come from bar 1.", 1, 1, 1, true);
	GameTooltip:AddLine("\nWhen you are in a form or stance, the buttons shown for page 1 come from one of bars 7 through 10.", 1, 1, 1, true);
	GameTooltip:AddLine("\nWhen you have been given temporary abilties by the game (such as when you are in a vehicle or using mind control), the buttons shown for page 1 come from action pages 12 (vehicleui, possessbar) or 14 (overridebar).", 1, 1, 1, true);
	GameTooltip:Show();
end

local function defaultBar12BindingsTooltip(self)
	-- self == the checkbox
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 280);
	GameTooltip:SetText("Use default bindings");
	GameTooltip:AddLine("This allows you to use the default main action bar's key bindings, in addition to any that you define for bar 12.", 1, 1, 1, true);
	GameTooltip:AddLine("\nYou do not have to unbind the keys from the default main action bar.", 1, 1, 1, true);
	GameTooltip:Show();
end

local function abCommandsTooltip(self)
	-- self == the ? button
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 35);
	GameTooltip:SetText("Previous/Next Action Bar commands");
	GameTooltip:AddLine("These two commands can be found in the game's Key Bindings window.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThey allow you to cycle through the main action bar's six pages of buttons when you press the key bound to the command, or click the game's main action bar arrow buttons.", 1, 1, 1, true);
	GameTooltip:AddLine("\nPages 1 and 2 cannot be ignored.", 1, 1, 1, true);
	GameTooltip:AddLine("\nPages 3 through 6 can be ignored by enabling the game's four action bars via the game's Interface options window.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe 'Right Bar' controls whether page 3 is ignored.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe 'Right Bar 2' controls whether page 4 is ignored.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe 'Bottom Right Bar' controls whether page 5 is ignored.", 1, 1, 1, true);
	GameTooltip:AddLine("\nThe 'Bottom Left Bar' controls whether page 6 is ignored.", 1, 1, 1, true);
	GameTooltip:AddLine("\nNote: Due to the way the game's extra action bars work, it is not possible to ignore page 4 without also ignoring page 3.", 1, 1, 1, true);
	GameTooltip:AddLine("\nEnabling an action bar will also cause the bar to appear on the screen.", 1, 1, 1, true);
	GameTooltip:AddLine("\nTo keep the enabled bars hidden, use the four options provided for this purpose in the 'Bar 12 Options' section of the CT_BarMod Options window.", 1, 1, 1, true);
	GameTooltip:AddLine("\nNote: Hiding the 'Right Bar' will automatically hide the 'Right Bar 2' as well.", 1, 1, 1, true);
	GameTooltip:Show();
end


----------
-- Options frame

local optionsFrameList;
local function optionsInit()
	optionsFrameList = module:framesInit();
end
local function optionsGetData()
	return module:framesGetData(optionsFrameList);
end
local function optionsAddFrame(offset, size, details, data)
	module:framesAddFrame(optionsFrameList, offset, size, details, data);
end
local function optionsAddObject(offset, size, details)
	module:framesAddObject(optionsFrameList, offset, size, details);
end
local function optionsAddScript(name, func)
	module:framesAddScript(optionsFrameList, name, func);
end
local function optionsAddTooltip(text)
	module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL); end);
end
local function optionsBeginFrame(offset, size, details, data)
	module:framesBeginFrame(optionsFrameList, offset, size, details, data);
end
local function optionsEndFrame()
	module:framesEndFrame(optionsFrameList);
end

module.frame = function()

	-- Prints a message only the first time that the user views the CT_BarMod options
	-- This is necessary to prevent taint from the keybinding options affecting battleground queuing
	DEFAULT_CHAT_FRAME:AddMessage("CT_BarMod:  When you are done, please type:  /console reloadui",1,1,.5);
	
	local textColor0 = "1.0:1.0:1.0";
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local offset;

	optionsInit();

	----------
	-- Tips
	----------

	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctbar, /ctbm, or /ctbarmod to open this options window directly.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#Bars are only movable when this options window is open.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#Some options if changed will only update when you are not in combat.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 5*14, "font#t:0:%y#s:0:%s#l:13:0#r#To hide or show one of the bars in a macro (when not in combat), you can use /ctbar hide, or /ctbar show, followed by the bar number. For example, to hide bar 2 use: /ctbar hide 2#" .. textColor2 .. ":l");
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#CT_BarMod supports the Masque addon which can change the appearance of the action buttons.#" .. textColor2 .. ":l");
	optionsEndFrame();

	----------
	-- Options window
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Options window");

		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:dragHideTooltip#Hide drag frame tooltip");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:dragOnTop#Display drag frame on top of buttons");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:dragTransparent#Drag frame is always transparent");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:clampFrames#Cannot drag bars completely off screen");
		if (CT_BottomBar) then
			optionsAddObject( -5,   26, "checkbutton#tl:20:%y#i:showCTBottomBar#o:showCTBottomBar#Show drag frames for CT_BottomBar bars");
		end
	optionsEndFrame();

	----------
	-- General Options
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#General");

		optionsAddObject(-10,   14, "font#tl:20:%y#v:ChatFontNormal#Out of Range:");
		optionsAddObject( 14,   20, "dropdown#tl:90:%y#n:CT_BarModDropdown1#o:colorLack:1#Color button red#Fade button out#No change");

		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:displayBindings:true#Display key bindings");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:displayRangeDot:true#Display range dot if there is no key binding");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:displayActionText:true#Display macro names");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:hideTooltip#Hide action button tooltips");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:hideGlow#Disable spell alert animations");

		optionsBeginFrame( -5,   26, "checkbutton#tl:20:%y#o:hideGrid#Hide empty button slots")
		--	if module:getGameVersion() >= 10 then
		--		optionsAddTooltip("This option is only available in Classic.")
		--		optionsAddScript("onload", function(btn)
		--			btn.text:SetTextColor(0.5, 0.5, 0.5)
		--		end)
		--	end
		optionsEndFrame()
	
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:buttonLock#Button lock (require a key to move buttons)");
		optionsAddObject(  0,   14, "font#tl:50:%y#v:ChatFontNormal#Move buttons key:");
		optionsAddObject( 14,   20, "dropdown#tl:140:%y#n:CT_BarModDropdown_buttonLockKey#o:buttonLockKey:3#Alt#Ctrl#Shift");

		--optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:clickDirection:true#Activate on key down only");
		--optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:clickIncluded#Activate button on key or mouse down");
		
		local SetCVar = SetCVar or C_CVar.SetCVar;	--retail vs classic
		local GetCVar = GetCVar or C_CVar.GetCVar;
		optionsBeginFrame( -20,   30,  "button#t:0:%y#s:200:%s#v:GameMenuButtonTemplate#Toggle Action Key Up/Down")
			optionsAddScript("onclick", function()
				if (GetCVar("ActionButtonUseKeyDown") == "1") then
					SetCVar("ActionButtonUseKeyDown", "0");
					CT_BarMod_OnMouseDownCheckButton:Hide();
				else
					SetCVar("ActionButtonUseKeyDown", "1");
					CT_BarMod_OnMouseDownCheckButton:Show()
				end
				updateClickDirection();
			end);
			local timeElapsed = 0;
			optionsAddScript("onupdate", function(font, elapsed)
				timeElapsed = timeElapsed + elapsed;
				if (timeElapsed < 0.25) then return; end
				timeElapsed = 0;
				if (GetCVar("ActionButtonUseKeyDown") == "1") then
					if module:getGameVersion() >= 10 then
						CT_BarMod_ToggleKeyFontString:SetText("Currently responds to |cFFFFFF99mouse down|r & |cFFFFFF99 key down|r|cFFFF9999\n\nStarting in Dragonflight,\n keyboard-down implies mouse-down");
					elseif module:getOption("onMouseDown") then
						CT_BarMod_ToggleKeyFontString:SetText("Currently responds to |cFFFFFF99mouse down|r & |cFFFFFF99 key down");
					else
						CT_BarMod_ToggleKeyFontString:SetText("Currently responds to |cFFFFFF99mouse up|r & |cFFFFFF99 key down");
					end
				else
					CT_BarMod_ToggleKeyFontString:SetText("Currently responds to |cFFFFFF99mouse up|r & |cFFFFFF99 key up");
				end
			end);
			optionsAddScript("onenter", function(button)
				module:displayTooltip(button, {
					"Toggle Key Up/Down", 
					"Toggles console variable 'ActionButtonUseKeyDown' between 0 and 1", 
					" ", 
					"|cFFFFFF99Action on Key Release Up:", 
					"- Same as typing |cFFFFFFFF/console ActionButtonUseKeyDown 0|r", 
					"- All buttons will respond to |cFFFFFFFFmouse-up|r and |cFFFFFFFFkey-up|r", 
					" ", 
					"|cFFFFFF99Action on Key Press Down:", 
					"- Same as typing |cFFFFFFFF/console ActionButtonUseKeyDown 1|r", 
					"- All buttons will respond to |cFFFFFFFFkey-down|r", 
					"- Unlocks more options for mouse |cFFFFFFFFup or down|r and", 
					" ", 
					"|cFF666666Console variables persist even if you get rid of addons",
					"|cFF666666but can be reset by typing /console cvar_reset"
				}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
			end);
		optionsEndFrame();
		
		optionsBeginFrame( -10, 26, "checkbutton#tl:50:%y#o:onMouseDown:false#n:CT_BarMod_OnMouseDownCheckButton#Also respond to mouse-down");
			optionsAddScript("onenter", function(checkbutton)
				module:displayTooltip(checkbutton, {
					"Also respond to mouse-down",
					"- Actions trigger when you press a mouse button, instead of release",
					"- Caution!  It even triggers when you are dragging a button to a new slot",
				}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
			end);
			optionsAddScript("onshow", function(checkbutton)
				if (GetCVar("ActionButtonUseKeyDown") == "0") then
					checkbutton:Hide();
				elseif module:getGameVersion() >= 10 then
					checkbutton:Disable()
					checkbutton:SetChecked(true)
					checkbutton.Text:SetTextColor(0.5, 0.5, 0.5)
				end
			end);
		optionsEndFrame();
		
		optionsAddObject(-20, 5*13, "font#tl:20:%y#r#v:ChatFontNormal#n:CT_BarMod_ToggleKeyFontString#Toggle mouse/key press down or release up");
		
	optionsEndFrame();

	----------
	-- Moving other UI elements
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Shifting other UI elements");
		
		if (ChallengeMode_LoadUI) then
			optionsAddObject(-15, 14, "font#tl:20:%y#v:ChatFontNormal#Pull foward certain frames:");
			optionsAddFrame(-5, 26, "checkbutton#tl:20:%y#o:pullForwardChallengeMode:true#Mythic+ Keystone Interface");
		end
		if (CovenantSanctum_LoadUI) then
			optionsAddFrame(6, 26, "checkbutton#tl:20:%y#o:pullForwardCovenantSanctum:true#Covenant Sanctum Interface");
		end

		optionsAddObject( -15,   26, "checkbutton#tl:20:%y#o:shiftParty:true#Shift default party frames to the right");
		optionsAddFrame( -10,   17, "slider#tl:50:%y#s:220:%s#o:shiftPartyOffset:37#Position = <value>#0:200:1");
		optionsAddObject(-10,   26, "checkbutton#tl:20:%y#o:shiftFocus:true#Shift default focus frame to the right");
		optionsAddFrame( -10,   17, "slider#tl:50:%y#s:220:%s#o:shiftFocusOffset:37#Position = <value>#0:200:1");

		if module:getGameVersion() <= 9 then
			if (CT_BottomBar) then optionsAddObject(-15, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#These options can be overridden by CT_BottomBar#" .. textColor2 .. ":l"); end
			optionsBeginFrame( -5,   26, "checkbutton#tl:20:%y#i:ctbar_shiftShapeshift#o:shiftShapeshift:true#Shift default class bar up");
				optionsAddScript("onshow",
					function(self)
						if ((CT_BottomBar and CT_BottomBar.ctClassBar and not CT_BottomBar.ctClassBar.isDisabled) or (CT_BottomBar and not CT_BottomBar.ctClassBar)) then
							-- The custom CT_BB class bar is present in this version
							self:SetAlpha(.5);
						else
							-- Either CT_BB is not installed, or the custom CT_BB class bar has been disabled
							self:SetAlpha(1);
						end
					end
				);
				optionsAddScript("onenter",
					function(self)
						GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 120, -5);
						GameTooltip:SetText("|cFFCCCCCCMoves the class/stance bar further from the bottom of screen.");
						if ((CT_BottomBar and CT_BottomBar.ctClassBar and not CT_BottomBar.ctClassBar.isDisabled) or (CT_BottomBar and not CT_BottomBar.ctClassBar)) then
							GameTooltip:AddLine("|cFFFF9999Currently overriden by CT_BottomBar.");
						end
						GameTooltip:Show();
					end
				);
				optionsAddScript("onleave",
					function(self)
						GameTooltip:Hide();
					end
				);
			optionsEndFrame();
			optionsBeginFrame(  6,   26, "checkbutton#tl:20:%y#i:ctbar_shiftPet#o:shiftPet:true#Shift default pet bar up");
				optionsAddScript("onshow",
					function(self)
						if (CT_BottomBar and CT_BottomBar.ctPetBar) then
							-- This version of CT_BottomBar supports deactivation of this bar.
							if (not CT_BottomBar.ctPetBar.isDisabled) then
								-- The bar is activated, 
								-- Let CT_BottomBar handle it.
								self:SetAlpha(.5);
							else
								self:SetAlpha(1);
							end
						elseif (CT_BottomBar) then
							-- This version of CT_BottomBar does not support deactivation of this bar.
							-- Let CT_BottomBar handle it.
							self:SetAlpha(.5);
						else
							-- CT_BottomBar isn't even installed
							self:SetAlpha(1);
						end
					end
				);
				optionsAddScript("onenter",
					function(self)
						GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 120, -5);
						GameTooltip:SetText("|cFFCCCCCCMoves the pet bar further from the bottom of screen.");
						if ((CT_BottomBar and CT_BottomBar.ctPetBar and not CT_BottomBar.ctPetBar.isDisabled) or (CT_BottomBar and not CT_BottomBar.ctPetBar)) then
							GameTooltip:AddLine("|cFFFF9999Currently overriden by CT_BottomBar.");
						end
						GameTooltip:Show();
					end
				);
				optionsAddScript("onleave",
					function(self)
						GameTooltip:Hide();
					end
				);
			optionsEndFrame();
			optionsAddFrame( -10,   17, "slider#tl:50:%y#s:220:%s#o:shiftPetOffset:113#Position = <value>#0:200:1");
			optionsBeginFrame( -5,   26, "checkbutton#tl:20:%y#i:ctbar_shiftPossess#o:shiftPossess:true#Shift default possess bar up");
						optionsAddScript("onshow",
							function(self)
								if ((CT_BottomBar and CT_BottomBar.ctPossess and not CT_BottomBar.ctPossess.isDisabled) or (CT_BottomBar and not CT_BottomBar.ctPossess)) then
									-- The custom CT_BB class bar is present in this version
									self:SetAlpha(.5);
								else
									-- Either CT_BB is not installed, or the custom CT_BB class bar has been disabled
									self:SetAlpha(1);
								end
							end
						);
						optionsAddScript("onenter",
							function(self)
								GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 120, -5);
								GameTooltip:SetText("|cFFCCCCCCMoves the default possess bar further from the bottom of screen.");
								if ((CT_BottomBar and CT_BottomBar.ctPossess and not CT_BottomBar.ctPossess.isDisabled) or (CT_BottomBar and not CT_BottomBar.ctPossess)) then
									GameTooltip:AddLine("|cFFFF9999Currently overriden by CT_BottomBar.");
								end
								GameTooltip:Show();
							end
						);
						optionsAddScript("onleave",
							function(self)
								GameTooltip:Hide();
							end
						);
			optionsEndFrame();
			-- removed from game in 2012 -- optionsAddObject(  6,   26, "checkbutton#tl:20:%y#i:ctbar_shiftMultiCast#o:shiftMultiCast:true#Shift default multicast bar up");
		end
	optionsEndFrame();

	----------
	-- Button skins options
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Skinning Buttons");

		optionsAddObject( -2, 4*14, "font#t:0:%y#s:0:%s#l:22:0#r#Buttons can be skinned using the skins included with CT_BarMod, or using an addon called Masque and some downloaded skins.#" .. textColor2 .. ":l");

		optionsAddObject(-10,   14, "font#tl:22:%y#Using CT_BarMod");
		optionsAddObject( -8,   14, "font#tl:42:%y#v:ChatFontNormal#Skin to use:");
		local menu = "";
		for k, skin in ipairs(module.skinsList) do
			menu = menu .. "#" .. skin.__CTBM__skinName;
		end
		optionsAddObject( 14,   20, "dropdown#tl:120:%y#n:CT_BarModDropdownSkin#o:skinNumber:1" .. menu);
		optionsAddObject(  0,   26, "checkbutton#tl:38:%y#o:backdropShow#Show backdrop texture.");

		optionsAddObject(-10,   14, "font#tl:22:%y#Using Masque");
		optionsAddObject( -5,   26, "checkbutton#tl:38:%y#o:skinMasque#Skin the buttons using Masque");
		optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:42:0#r#To select and configure skins, open Masque's option window (/msq).#" .. textColor2 .. ":l");
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:42:0#r#The CT_BarMod skins are also available in Masque's list of skins when CT_BarMod is loaded.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:42:0#r#If Masque is not loaded then the buttons will be skinned using the CT_BarMod settings.#" .. textColor2 .. ":l");

		optionsAddObject(-10,   14, "font#tl:22:%y#General settings");
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:42:0#r#The following option might make it easier to see a skin's backdrop texture. It may have no effect on some skins.#" .. textColor2 .. ":l");
		optionsAddObject(  0,   26, "checkbutton#tl:40:%y#o:useNonEmptyNormal#Use non-empty slot texture in empty slots");
	optionsEndFrame();

	----------
	-- Cooldown Options
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		local fonts = "";
		for i, value in ipairs(fontTypeListSorted) do
			fonts = fonts .. "#" .. value;
		end
		local r,g,b,a = unpack(fontDefaultColor);
		local styles = "";
		for i, value in ipairs(fontStyleListSorted) do
			styles = styles .. "#" .. value;
		end

		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Cooldowns");

		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:displayCount:true#Display cooldown counts");
		

		optionsAddObject( -5,   14, "font#tl:60:%y#v:ChatFontNormal#Color:");
		optionsAddObject( 14,   16, "colorswatch#tl:100:%y#s:16:%s#o:cooldownFontColor:" ..r.. "," ..g.. "," ..b.. "," ..a.. "#true");

		optionsAddObject(-14,   14, "font#tl:60:%y#v:ChatFontNormal#Font:");
		optionsAddObject( 14,   20, "dropdown#tl:80:%y#n:CT_BarModDropdownCooldownType#o:cooldownFontTypeNum:" .. fontDefaultTypeNum .. fonts);

		optionsAddObject(-10,   14, "font#tl:60:%y#v:ChatFontNormal#Style:");
		optionsAddObject( 14,   20, "dropdown#tl:80:%y#n:CT_BarModDropdownCooldownStyle#o:cooldownFontStyleNum:" .. fontDefaultStyleNum .. styles);

		optionsAddFrame( -20,   17, "slider#t:0:%y#s:175:%s#o:cooldownFontSize:" .. fontDefaultSize .. "#Size = <value>#10:30:1");
		
		optionsAddObject(-10,   26, "checkbutton#tl:20:%y#o:displayRecharge:true#Display recharge sweep");
		
		optionsAddObject(-10,   14, "font#t:0:%y#v:ChatFontNormal#Flare when cooldown finishes, if longer than:");
		optionsAddObject(-20,   17, "slider#t:0:%y#s:175:%s#o:minimumCooldownToBling:0#<value> seconds:0 sec:30 sec#0:30:0.5");
	optionsEndFrame();

	----------
	-- Default Blizzard
	----------

	optionsBeginFrame(-30, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Blizzard Bars");
		
		-- Blizzard Action Buttons
		optionsAddObject(-10,   17, "font#tl:20:%y#v:GameFontNormal#Blizzard Action Buttons");
		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#Select which of the following CT_BarMod options to also apply to the buttons on Blizzard's action bars.#" .. textColor2 .. ":l");
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:defbarShowRange:true#Apply the 'Out of range' option");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:defbarShowBindings:true#Apply 'Display key bindings' and 'range dot'");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:defbarShowActionText:true#Apply the 'Display macro names' option");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:defbarSetUnitAttributes:true#Apply the 'Unit attributes'");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:defbarHideTooltip:true#Apply the 'Hide action button tooltips' option");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:defbarShowCooldown:true#Apply the 'Display cooldown counts' option");	
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:defbarShowRecharge:true#Apply the 'Display recharge sweep' option");

		-- Blizzard Bottom-Left Bar
		optionsAddObject(-10,   17, "font#tl:20:%y#v:GameFontNormal#Learning Abilities");
		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#These options take effect when levelling up or learning a special zone ability.#" .. textColor2 .. ":l");
		optionsBeginFrame( -5,   26, "checkbutton#tl:20:%y#o:disableIconIntro:true#Prevent disabled bars from turning on");
			optionsAddTooltip({"Prevent disabled bars from turning on", "Prevents the 'bottom left' action bar from turning itself on when the action bar is full.#0.9:0.9:0.9"});
		optionsEndFrame();
		optionsBeginFrame( -5,   26, "checkbutton#tl:20:%y#o:newZoneAbilities:true#Clear new zone abilities via custom bars");
			optionsAddTooltip({"Stop new abilities from turning bars on", "After dragging a newly-learned ability to a custom CT bar, this will interrupt any default animations or bonus buttons#0.9:0.9:0.9"});
		optionsEndFrame();
	optionsEndFrame();
	
	
	----------
	-- Default Bar Positions
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Default Bar Positions");

		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#There are two sets of default positions for CT_BarMod bars: the original CT_BarMod positions and the standard UI positions.#" .. textColor2 .. ":l");
		optionsAddObject(  0, 4*14, "font#t:0:%y#s:0:%s#l:20:0#r#Using the standard positions puts four of the CT_BarMod bars and their buttons in the same locations as the ones in the standard user interface.#" .. textColor2 .. ":l");
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:stdPositions#Standard bar positions (then click Reset)");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:newPositions:true:true#New characters use standard UI positions");  -- Account wide setting
		optionsBeginFrame( -14,   30, "button#t:0:%y#s:180:%s#n:CT_BarMod_ResetBarPositions_Button#v:GameMenuButtonTemplate#Reset bar positions");
			optionsAddScript("onclick",
				function(self)
					resetGroupPositions();
				end
			);
		optionsEndFrame();
	optionsEndFrame();

	----------
	-- Enable bars
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b#i:enablebars");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Enable Bars");

		-- Although the default for all showGroup options is true,
		-- the group:new() routine forces all groups with a group id
		-- value of 6 or higher to be false. This prevents having all
		-- groups appear on screen at the same time for someone who
		-- never used the addon before.

		-- Bar 1 == groupId 10, Bar 2 == groupId 1, etc, Bar 10 == groupId 9, Bar 11 == groupId 11, Bar 12 == groupId 12

		-----
		-- Bars 1 to 6
		-----
		optionsAddObject(-10, 4*14, "font#t:0:%y#s:0:%s#l:20:0#r#The first six action bars can be used as general purpose bars for any class or spec. The buttons on these bars are not associated with any particular form or stance.#" .. textColor2 .. ":l");

		optionsAddObject(  0,   26, "checkbutton#tl:25:%y#i:showGroup10#o:showGroup10:true#Enable bar 1");
		optionsAddObject(  6,   26, "checkbutton#tl:25:%y#i:showGroup1#o:showGroup1:true#Enable bar 2");
		optionsAddObject(  6,   26, "checkbutton#tl:25:%y#i:showGroup2#o:showGroup2:true#Enable bar 3");

		optionsAddObject(3*22,  26, "checkbutton#tl:165:%y#i:showGroup3#o:showGroup3:true#Enable bar 4");
		optionsAddObject(  6,   26, "checkbutton#tl:165:%y#i:showGroup4#o:showGroup4:true#Enable bar 5");
		optionsAddObject(  6,   26, "checkbutton#tl:165:%y#i:showGroup5#o:showGroup5:true#Enable bar 6");

		-----
		-- Bars 7 to 10
		-----
		do
			optionsAddObject(-15, 4*14, "font#t:0:%y#s:0:%s#l:20:0#r#Depending on your class, spec, and current form or stance, the buttons from bars 7 through 10 may be shown on the main action bar when you select its page 1.#" .. textColor2 .. ":l");

			local _, class = UnitClass("player");
			local text;

			-- Bar 7
			if (class == "DRUID") then
				text = "(cat form)";
			elseif (class == "ROGUE") then
				text = "(stealth, shadow dance)";
			elseif (class == "PRIEST") then
				text = "(shadow form)";
			else
				text = "(general purpose)";
			end
			optionsAddObject(  0,   26, "checkbutton#tl:25:%y#i:showGroup6#o:showGroup6:true#Enable bar 7" .. "  " .. text);

			-- Bar 8
			text = "(general purpose)";
			optionsAddObject(  6,   26, "checkbutton#tl:25:%y#i:showGroup7#o:showGroup7:true#Enable bar 8" .. "  " .. text);

			-- Bar 9
			if (class == "DRUID") then
				text = "(bear form)";
			else
				text = "(general purpose)";
			end
			optionsAddObject(  6,   26, "checkbutton#tl:25:%y#i:showGroup8#o:showGroup8:true#Enable bar 9" .. "  " .. text);

			-- Bar 10
			if (class == "DRUID") then
				text = "(moonkin form)";
			else
				text = "(general purpose)";
			end
			optionsAddObject(  6,   26, "checkbutton#tl:25:%y#i:showGroup9#o:showGroup9:true#Enable bar 10" .. "  " .. text);
		end

		-----
		-- Bar 11 (Control bar)
		-----
		optionsAddObject(-15, 5*14, "font#t:0:%y#s:0:%s#l:20:0#r#Bar 11 is only used when the game assigns you some temporary abilties (mind control, vehicles, etc). You cannot assign abilities to this bar yourself. This bar is not needed if you are using bar 12.#" .. textColor2 .. ":l");
		optionsAddObject(  0,   26, "checkbutton#tl:25:%y#i:showGroup11#o:showGroup11:true#Enable bar 11 (Control bar)");

		-----
		-- Bar 12 (Action bar )
		-----
		optionsAddObject(-15, 5*14, "font#t:0:%y#s:0:%s#l:20:0#r#Bar 12 can show one of six different pages of buttons. The buttons on each page are a copy of the buttons found on one of the other bars. Refer to the 'Enable bar 12' option's tooltip for more details.#" .. textColor2 .. ":l");
		optionsAddObject(  0,   26, "checkbutton#tl:25:%y#i:showGroup12#o:showGroup12:true#Enable bar 12 (Action bar)");

		if module:getGameVersion() >= 10 then
			optionsBeginFrame( -5,   26, "checkbutton#tl:25:%y#i:disableDragonflightActionBar#o:disableDragonflightActionBar:false#Disable the default main action bar")
				optionsAddScript("onshow", function(self)
					local opt = module:getOption("disableDragonflightActionBar")
					if CT_BottomBar then
						self:SetChecked(opt ~= false)
					else
						self:SetChecked(opt)
					end
				end)
				if CT_BottomBar then
					optionsAddTooltip({"Disable the default main action bar#"..textColor3, "CT_BottomBar has additional options affecting the action bar.#"..textColor1})
				end
			optionsEndFrame()
		elseif (CT_BottomBar) then
			-- Don't show this option if CT_BottomBar is not loaded.
			-- This option only works if CT_BottomBar 4.008 or greater is loaded.

			optionsAddObject( -5,   26, "checkbutton#tl:25:%y#i:disableDefaultActionBar#o:disableDefaultActionBar#Disable the default main action bar");

			optionsAddObject(  3, 2*14, "font#t:0:%y#s:0:%s#l:55:0#r#This option requires CT_BottomBar.#" .. textColor2 .. ":l");
			optionsAddObject(  0, 4*14, "font#t:0:%y#s:0:%s#l:55:0#r#Disabling or enabling the default main action bar requires reloading addons.#" .. textColor3 .. ":l");

			optionsBeginFrame(  -5,   30, "button#tl:55:%y#s:150:%s#n:CT_BarMod_DisableActionBar_Button#v:GameMenuButtonTemplate#Reload addons");
				optionsAddScript("onclick",
					function(self)
						ConsoleExec("RELOADUI");
					end
				);
			optionsEndFrame();
		end

		optionsAddScript("onshow",
			function(self)
				self.showGroup12:SetScript("OnEnter", enableBar12Tooltip);
			end
		);

	optionsEndFrame();

	----------
	-- Default key bindings options
	----------
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b#i:defkeyoptions");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Use Default Bars' Key Bindings");

		optionsAddObject(-10, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#These options allow you to use the key bindings that are assigned to buttons on the game's default bars.#" .. textColor2 .. ":l");
		optionsAddObject( -6, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#You do not have to unbind the keys from the default bars.#" .. textColor2 .. ":l");
		optionsAddObject( -6, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#In addition to using the default bars' key bindings, you can continue to assign key bindings directly to the CT_BarMod buttons.#" .. textColor2 .. ":l");

		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:bar3Bindings:true#Bar 3 (use bindings from Right Bar)");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:bar4Bindings:true#Bar 4 (use bindings from Right Bar 2)");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:bar5Bindings:true#Bar 5 (use bindings from Bottom Right Bar)");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:bar6Bindings:true#Bar 6 (use bindings from Bottom Left Bar)");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:actionBindings:true#Bar 12 (use bindings from Main Action Bar)");
	optionsEndFrame();


	----------
	-- Bar 12 options
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b#i:bar12options");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Bar 12 Options");

		optionsAddObject(-10,   14, "font#tl:15:%y#Previous/Next Action Bar commands");
		optionsBeginFrame(  20,   20, "button#tl:275:%y#s:20:%s#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter", abCommandsTooltip);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:30:0#r#To make these commands ignore certain bars, use the game's Interface options window to enable some action bars.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:30:0#r#Use the following options to keep the game's enabled action bars hidden:#" .. textColor2 .. ":l");

		optionsAddObject(  0,   26, "checkbutton#tl:35:%y#o:hideExtraBar6#Hide the game's Bottom Left Bar"); -- Page 6 (Bar 6)
		optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:hideExtraBar5#Hide the game's Bottom Right Bar"); -- Page 5 (Bar 5)
		optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:hideExtraBar3#Hide the game's Right Bar"); -- Page 3 (Bar 3)
		optionsAddObject(  6,   26, "checkbutton#tl:62:%y#o:hideExtraBar4#i:hideExtraBar4#Hide the game's Right Bar 2"); -- Page 4 (Bar 4)
		
		

		optionsAddScript("onshow",
			function(self)
				updateWidgets_hideExtraBars();
			end
		);
	optionsEndFrame();

	----------
	-- Bar options
	----------

		optionsBeginFrame(-20,    0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(   0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Bar Options");

		----------
		-- Select bar
		----------

		optionsAddObject(-15, 14, "font#tl:15:%y#v:ChatFontNormal#Select bar:");

		optionsBeginFrame(19, 24, "button#tl:80:%y#s:24:%s");
			optionsAddScript("onclick",
				function(self)
					module:setOption("prvsGroup", 1);  -- Actual value assigned to option is not important.
				end
			);
			optionsAddScript("onload",
				function(self)
					self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
					self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
					self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
					self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
				end
			);
		optionsEndFrame();

		optionsBeginFrame(24, 24, "button#tl:100:%y#s:24:%s");
			optionsAddScript("onclick",
				function(self)
					module:setOption("nextGroup", 1);  -- Actual value assigned to option is not important.
				end
			);
			optionsAddScript("onload",
				function(self)
					self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
					self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
					self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
					self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
				end
			);
		optionsEndFrame();

		do
			local menu = ""
			for groupNum, obj in ipairs(groupList) do
				menu = menu .. "#" .. obj.fullName;
			end
			optionsAddObject( 20,   20, "dropdown#tl:120:%y#n:CT_BarModDropdown2#o:editGroup" .. menu);
		end

		----------
		-- Appearance
		----------

		optionsAddObject(-10,   14, "font#tl:15:%y#Appearance");
		optionsAddObject( -6,   14, "font#tl:40:%y#v:ChatFontNormal#Orientation:");
		optionsAddObject( 14,   20, "dropdown#tl:100:%y#s:150:%s#n:CT_BarModDropOrientation#o:orientation:1#Left to right#Top to bottom");

		optionsAddObject(-10,   26, "checkbutton#tl:40:%y#i:barFlipHorizontal#o:barFlipHorizontal:false#Flip the bar horizontally");
		optionsAddObject(  3,   26, "checkbutton#tl:40:%y#i:barFlipVertical#o:barFlipVertical:false#Flip the bar vertically");

		optionsAddFrame( -18,   17, "slider#tl:42:%y#s:100:%s#o:barNumToShow:12#i:barNumToShow#Buttons = <value>#1:12:1");
		optionsBeginFrame(17,   17, "slider#tl:180:%y#s:100:%s#o:barColumns:12#i:columns#Columns = <value>#1:12:1");
			optionsAddScript("onload", function()
				updateGroupWidgets_Columns(currentEditGroup);
			end);
		optionsEndFrame();

		optionsAddFrame( -28,   17, "slider#tl:42:%y#s:238:%s#o:barSpacing:6#i:spacing#n:ctbarSpacing#Spacing = <value>#-36:72:1");
		optionsAddFrame( -28,   17, "slider#tl:42:%y#s:238:%s#o:barScale:1#i:scale#n:ctbarScale#Scale = <value>#0.25:2:0.01");

		----------
		-- Opacity
		----------

		optionsAddObject(-20,   14, "font#tl:15:%y#Opacity");
		optionsBeginFrame(-8,   17, "slider#tl:43:%y#s:238:%s#o:barOpacity:1#i:opacity#n:ctbarOpacity#Opacity = <value>#0:1:0.01");
			optionsAddTooltip({"Opacity", "Standard opacity when the mouse is overtop, or always if not fading.#0.9:0.9:0.9"});
		optionsEndFrame();
		optionsBeginFrame(-10,   26, "checkbutton#tl:40:%y#i:mouseover#o:barMouseover:false#Fade when mouse is not over the bar");
			optionsAddTooltip({"Fade when mouse is not over the bar", "Use the sliders below to determine how much it should fade outside and during combat.#0.9:0.9:0.9"});
			optionsAddScript("onload", function(obj)
				obj:HookScript("OnClick", function()
					if (obj:GetChecked()) then
						obj:GetParent().barFaded:SetAlpha(1);
						obj:GetParent().barFadedCombat:SetAlpha(1);
					else
						obj:GetParent().barFaded:SetAlpha(0.5);
						obj:GetParent().barFadedCombat:SetAlpha(0.5);
					end
				end);
			end);
		optionsEndFrame();
		optionsBeginFrame( -17,   17, "slider#tl:22:%y#s:120:%s#o:barFaded:0#i:barFaded#Outside Combat = <value>#0:1:0.01");
			optionsAddTooltip({"Fading outside combat", "Fade the bar outside combat, unless the mouse is hovering overtop.#0.9:0.9:0.9"});
		optionsEndFrame();
		optionsBeginFrame(  17,   17, "slider#tl:180:%y#s:120:%s#o:barFadedCombat:0#i:barFadedCombat#During Combat = <value>#0:1:0.01");
			optionsAddTooltip({"Fading during combat", "Fade the bar during combat, unless the mouse is hovering overtop.#0.9:0.9:0.9"});
		optionsEndFrame();


		----------
		-- Visibility
		----------
		optionsAddObject(-17,   15, "font#tl:15:%y#Visibility");

		-- Basic conditions

		optionsAddObject( -5,   20, "checkbutton#tl:15:%y#s:%s:%s#i:visBasic#o:visBasic#Use basic conditions");

		optionsAddObject( -4, 3*14, "font#t:0:%y#s:0:%s#l:50:0#r#Each bar has its own specific set of basic conditions that control when the bar is normally shown.#" .. textColor2 .. ":l");
		optionsAddObject( -4, 2*14, "font#t:0:%y#s:0:%s#l:50:0#r#The following additional conditions can change when the bar is shown.#" .. textColor2 .. ":l");
		optionsAddObject( -5,   26, "checkbutton#tl:50:%y#i:barHideInPetBattle#o:barHideInPetBattle:true#Hide when in a pet battle");
		optionsAddObject(  6,   26, "checkbutton#tl:50:%y#i:barHideInVehicle#o:barHideInVehicle:true#Hide when in a vehicle");
		optionsAddObject(  6,   26, "checkbutton#tl:50:%y#i:barHideInOverride#o:barHideInOverride:true#Hide when there is an override bar");
		optionsAddObject(  6,   26, "checkbutton#tl:50:%y#i:hideInCombat#o:barHideInCombat:false#Hide when in combat");
		optionsAddObject(  6,   26, "checkbutton#tl:50:%y#i:hideNotCombat#o:barHideNotCombat:false#Hide when not in combat");

		-- Advanced conditions

		optionsAddObject( -6,   20, "checkbutton#tl:15:%y#s:%s:%s#i:visAdvanced#o:visAdvanced#Use advanced conditions");

		optionsBeginFrame(20,   20, "button#tl:194:%y#s:20:%s#i:visHelp0#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					advancedVisTooltip0(self, currentEditGroup);
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
			optionsAddScript("onclick",
				function(self)
					if (IsShiftKeyDown()) then
						local editBox = groupFrame.conditionEB;
						editBox:HighlightText(0, 0);
						editBox:ClearFocus();
						editBox:SetText(buildVisBasicCondition(currentEditGroup));
					end
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  20,   20, "button#tl:222:%y#s:20:%s#i:visHelp1#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					advancedTooltip1(self);
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  21,   20, "button#tl:250:%y#s:20:%s#i:visHelp2#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					advancedTooltip2(self);
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  21,   20, "button#tl:278:%y#s:20:%s#i:visHelp2#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					advancedTooltip3(self);
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(   0,  90, "frame#tl:40:%y#br:tr:0:%b");
			optionsAddScript("onload",
				function(self)
					local width = 260;
					local height = 90;
					local frame = module:createMultiLineEditBox("CT_BarMod_AdvancedEdit", width, height, self, 1);
					frame:Show();
					do
						local function update(self)
							self:HighlightText(0, 0);
							self:ClearFocus();
						end
						frame.editBox:SetScript("OnEscapePressed", update);
						frame.editBox:SetScript("OnTabPressed", update);
						frame.editBox:SetScript("OnEditFocusLost", update);
					end
					frame.editBox:HookScript("OnTextChanged",
						function(self)
							if (not currentEditGroup) then
								return;
							end
							if ( self:GetText() ~= (module:getOption("barCondition" .. currentEditGroup) or "") ) then
								groupFrame.visSave:Enable();
								groupFrame.visUndo:Enable();
							end
						end
					);
					self:GetParent().conditionEB = frame.editBox;
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  -2,   22, "button#tl:60:%y#s:60:%s#i:visTest#v:UIPanelButtonTemplate#Test");
			optionsAddScript("onclick",
				function(self)
					local editBox = groupFrame.conditionEB;
					local cond = buildCondition( editBox:GetText() );
					local action, target = SecureCmdOptionParse(cond);
					print("Tested: ", cond);
					if (target) then
						print("Target used: ", target);
					end
					if (action) then
						print("Result: ", action);
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Test conditions");
					GameTooltip:AddLine("This tests the conditions in the edit box in order to display the current action that will be performed when the conditions are saved.\n\nThis button does not have any effect on the bar.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  23,   22, "button#tl:140:%y#s:60:%s#i:visSave#v:UIPanelButtonTemplate#Save");
			optionsAddScript("onload",
				function(self)
					self:Disable();
				end
			);
			optionsAddScript("onclick",
				function(self)
					local editBox = groupFrame.conditionEB;
					editBox:HighlightText(0, 0);
					editBox:ClearFocus();
					local cond = editBox:GetText();
					module:setOption("barCondition", cond);
					self:Disable();
					editBox.ctUndo = cond;
					groupFrame.visUndo:Disable();
					if (IsShiftKeyDown()) then
						print(buildCondition(cond));
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Save changes");
					GameTooltip:AddLine("This saves the changes you've made to the conditions. The bar will not be affected by the modified conditions until you save the changes.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  23,   22, "button#tl:220:%y#s:60:%s#i:visUndo#v:UIPanelButtonTemplate#Undo");
			optionsAddScript("onload",
				function(self)
					self:Disable();
				end
			);
			optionsAddScript("onclick",
				function(self)
					local editBox = groupFrame.conditionEB;
					editBox:HighlightText(0, 0);
					editBox:ClearFocus();
					if (editBox.ctUndo) then
						editBox:SetText(editBox.ctUndo);
						self:Disable();
						groupFrame.visSave:Disable();
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Undo changes");
					GameTooltip:AddLine("This will undo all changes made to the conditions since they were last saved.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		----------
		-- Paging
		----------

		local menu = "#Ignore";
		for i = 1, 10 do
			menu = menu .. "#" .. "Page " .. i .. " (Bar " .. i .. ")";
		end
		menu = menu .. "#" .. "Page 11 (Multicast)";
		menu = menu .. "#" .. "Page 12 (Vehicle, Possess)";
		menu = menu .. "#" .. "Page 13 (Temp shapeshift)";
		menu = menu .. "#" .. "Page 14 (Override)";
--		for groupNum, obj in ipairs(groupList) do
--			if (obj.num >= 1 and obj.num <= 11) then
--				menu = menu .. "#" .. obj.fullName;
--			end
--		end

		optionsAddObject(-15,   15, "font#tl:15:%y#Paging");

		-- Basic conditions

		optionsAddObject( -5,   20, "checkbutton#tl:15:%y#s:%s:%s#i:pageBasic#o:pageBasic#Use basic conditions");

		optionsAddObject( -4, 3*14, "font#t:0:%y#s:0:%s#l:50:0#r#Each bar has its own specific set of basic conditions that control which buttons are normally shown.#" .. textColor2 .. ":l");
		optionsAddObject( -4, 3*14, "font#t:0:%y#s:0:%s#l:50:0#r#The following additional conditions can change which buttons are shown on the current bar.#" .. textColor2 .. ":l");

		optionsAddObject(-10,   14, "font#tl:50:%y#v:ChatFontNormal#Alt key down:");
		optionsAddObject( 14,   20, "dropdown#tl:130:%y#s:140:%s#n:CT_BarModDropdown_pageAltKey#o:pageAltKey:1" .. menu);

		optionsAddObject( -4,   14, "font#tl:50:%y#v:ChatFontNormal#Ctrl key down:");
		optionsAddObject( 14,   20, "dropdown#tl:130:%y#s:140:%s#n:CT_BarModDropdown_pageCtrlKey#o:pageCtrlKey:1" .. menu);

		optionsAddObject( -4,   14, "font#tl:50:%y#v:ChatFontNormal#Shift key down:");
		optionsAddObject( 14,   20, "dropdown#tl:130:%y#s:140:%s#n:CT_BarModDropdown_pageShiftKey#o:pageShiftKey:1" .. menu);

		-- Advanced conditions

		optionsAddObject( -6,   20, "checkbutton#tl:15:%y#s:%s:%s#i:pageAdvanced#o:pageAdvanced#Use advanced conditions");

		optionsBeginFrame(  20,   20, "button#tl:194:%y#s:20:%s#i:pageHelp0#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					advancedPageTooltip0(self, currentEditGroup);
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
			optionsAddScript("onclick",
				function(self)
					if (IsShiftKeyDown()) then
						local editBox = groupFrame.pageEB;
						editBox:HighlightText(0, 0);
						editBox:ClearFocus();
						editBox:SetText(module:buildPageBasicCondition(currentEditGroup));
					end
				end
			);

		optionsEndFrame();

		optionsBeginFrame(  20,   20, "button#tl:222:%y#s:20:%s#i:pageHelp1#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					advancedTooltip1(self);
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  21,   20, "button#tl:250:%y#s:20:%s#i:pageHelp2#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					advancedTooltip2(self);
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  21,   20, "button#tl:278:%y#s:20:%s#i:pageHelp3#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					advancedTooltip3(self);
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(   0,  90, "frame#tl:40:%y#br:tr:0:%b");
			optionsAddScript("onload",
				function(self)
					local width = 260;
					local height = 90;
					local frame = module:createMultiLineEditBox("CT_BarMod_pageAdvancedEdit", width, height, self, 1);
					frame:Show();
					do
						local function update(self)
							self:HighlightText(0, 0);
							self:ClearFocus();
						end
						frame.editBox:SetScript("OnEscapePressed", update);
						frame.editBox:SetScript("OnTabPressed", update);
						frame.editBox:SetScript("OnEditFocusLost", update);
					end
					frame.editBox:HookScript("OnTextChanged",
						function(self)
							if (not currentEditGroup) then
								return;
							end
							if ( self:GetText() ~= (module:getOption("pageCondition" .. currentEditGroup) or "") ) then
								groupFrame.pageSave:Enable();
								groupFrame.pageUndo:Enable();
							end
						end
					);
					self:GetParent().pageEB = frame.editBox;
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  -2,   22, "button#tl:60:%y#s:60:%s#i:pageTest#v:UIPanelButtonTemplate#Test");
			optionsAddScript("onclick",
				function(self)
					local editBox = groupFrame.pageEB;
					local cond = buildCondition( editBox:GetText() );
					local action, target = SecureCmdOptionParse(cond);
					print("Tested: ", cond);
					if (target) then
						print("Target used: ", target);
					end
					if (action) then
						print("Result: ", action);
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Test conditions");
					GameTooltip:AddLine("This tests the conditions in the edit box in order to display the current action that will be performed when the conditions are saved.\n\nThis button does not have any effect on the bar.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  23,   22, "button#tl:140:%y#s:60:%s#i:pageSave#v:UIPanelButtonTemplate#Save");
			optionsAddScript("onload",
				function(self)
					self:Disable();
				end
			);
			optionsAddScript("onclick",
				function(self)
					local editBox = groupFrame.pageEB;
					editBox:HighlightText(0, 0);
					editBox:ClearFocus();
					local cond = editBox:GetText();
					module:setOption("pageCondition", cond);
					self:Disable();
					editBox.ctUndo = cond;
					groupFrame.pageUndo:Disable();
					if (IsShiftKeyDown()) then
						print(buildCondition(cond));
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Save changes");
					GameTooltip:AddLine("This saves the changes you've made to the conditions. The bar will not be affected by the modified conditions until you save the changes.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  23,   22, "button#tl:220:%y#s:60:%s#i:pageUndo#v:UIPanelButtonTemplate#Undo");
			optionsAddScript("onload",
				function(self)
					self:Disable();
				end
			);
			optionsAddScript("onclick",
				function(self)
					local editBox = groupFrame.pageEB;
					editBox:HighlightText(0, 0);
					editBox:ClearFocus();
					if (editBox.ctUndo) then
						editBox:SetText(editBox.ctUndo);
						self:Disable();
						groupFrame.pageSave:Disable();
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Undo changes");
					GameTooltip:AddLine("This will undo all changes made to the conditions since they were last saved.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		----------
		-- Frame scripts
		----------

		optionsAddScript("onload",
			function(self)
				groupFrame = self;
				updateGroupWidgets(currentEditGroup);

				module:setRadioButtonTextures(self.visBasic);
				module:setRadioButtonTextures(self.visAdvanced);

				module:setRadioButtonTextures(self.pageBasic);
				module:setRadioButtonTextures(self.pageAdvanced);
			end
		);
		
		
		
		----------
		-- Unit Attributes
		----------

		optionsAddObject(-20,   14, "font#tl:15:%y#Unit Attributes");
		local unitAttributeTooltip = {"Unit Attributes", "Which unit should spells target with each type of click?", "Note: this only applies to mouse clicks."}
		local unitAttributeOptions = "#Default#Target#Player#Pet" .. (FocusFrame and "#Focus" or "");
		optionsAddObject(-10,   14, "font#tl:10:%y#v:ChatFontNormal#Left click:");
		optionsBeginFrame( 14,   20, "dropdown#tl:90:%y#s:150:%s#o:unitAttribute1" .. unitAttributeOptions);
			optionsAddTooltip(unitAttributeTooltip);
		optionsEndFrame();
		optionsAddObject(-10,   14, "font#tl:10:%y#v:ChatFontNormal#Right click:");
		optionsBeginFrame( 14,   20, "dropdown#tl:90:%y#s:150:%s#o:unitAttribute2" .. unitAttributeOptions);
			optionsAddTooltip(unitAttributeTooltip);
		optionsEndFrame();
		optionsAddObject(-10,   14, "font#tl:10:%y#v:ChatFontNormal#Middle click:");
		optionsBeginFrame( 14,   20, "dropdown#tl:90:%y#s:150:%s#o:unitAttribute3" .. unitAttributeOptions);
			optionsAddTooltip(unitAttributeTooltip);
		optionsEndFrame();
			
	optionsEndFrame();

	----------
	-- Key bindings
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Button Options");
		optionsAddObject(-10,   14, "font#tl:10:%y#v:ChatFontNormal#Option:");
		optionsAddObject( 14,   20, "dropdown#tl:50:%y#s:190:%s#n:CT_BarModDropButtonOptions#o:buttonOptions:1#Key bindings#Flyout direction");
		optionsAddObject(-10, 4*14, "font#t:5:%y#v:GameFontNormal#i:instruction");
		for i = 1, 13 do
			optionsAddFrame( 1,   25, "button#tl:20:%y#s:0:%s#r:-20:0#i:" .. i, module.keyBindingTemplate);
		end
		optionsAddScript("onload", module.keyBindingOnLoad);
		optionsAddScript("onshow", module.keyBindingOnShow);
		optionsAddScript("onkeydown", module.keyBindingOnKeyDown);
	optionsEndFrame();

	----------
	-- Reset Options
	----------

	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,    1, "texture#tl:5:%y#br:tr:0:%b#1:1:1");

		optionsAddObject(-15,   17, "font#tl:5:%y#v:GameFontNormalLarge#Reset CT_BarMod Options");
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:resetAll#Reset options for all of your characters");
		optionsBeginFrame( -10,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#Reset options");
			optionsAddScript("onclick",
				function(self)
					if (module:getOption("resetAll")) then
						CT_BarModOptions = {};
					else
						if (not CT_BarModOptions or not type(CT_BarModOptions) == "table") then
							CT_BarModOptions = {};
						else
							CT_BarModOptions[module:getCharKey()] = nil;
						end
					end
					ConsoleExec("RELOADUI");
				end
			);
		optionsEndFrame();
		optionsAddObject( -2, 4*14, "font#tl:50:%y#s:0:%s#l#r#Note: This will reset options and bar positions to default and then reload your UI. This will not reset any key bindings.#" .. textColor3 .. ":l");
	optionsEndFrame();

	optionsAddScript("onshow",
		function(self)
			showGroupHeaders(self);
		end
	);

	optionsAddScript("onhide",
		function(self)
			hideGroupHeaders(self);
		end
	);

	optionsAddScript("onload",
		function(self)
			theOptionsFrame = self;
		end
	);

	return "frame#all", optionsGetData();
end

local function CT_BarMod_OnEvent(self, event, arg1, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		CT_BarMod_UpdateVisibility();
		if (module:usingMasque()) then
			module:reskinMasqueGroups();
		end

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (module.needSetAttributes) then
			module:setAttributes();
		end
		if (module.needRegisterPagingStateDrivers) then
			module:registerAllPagingStateDrivers();
		end
		if (module.needHideExtraBars) then
			module:hideExtraBars();
		end
		if (module.needUpdateClickDirection) then
			updateClickDirection();
		end
		CT_BarMod_UpdateVisibility();
		updateGroups();

	elseif (event == "PLAYER_REGEN_DISABLED") then
		if (module.needSetActionBindings) then
			module.setActionBindings();
		end
		CT_BarMod_UpdateVisibility();
		updateGroups();
	end
end

-------------------
-- Handle options

module.optionUpdate = function(self, optName, value)
	-- Update an option.

	-- Group id of the group currently being edited.
	local localGroupId = currentEditGroup;

	if (optName ~= "init" and value == nil) then
		-- Prevent ininfite loop when clearing an option
		-- from within this function.
		return;
	end

	-- Translate option name, value, etc. if necessary before processing the option.
	if (optName == "visBasic") then
		self:setOption(optName, nil);
		optName = "barVisibility";
		value = 1;

	elseif (optName == "visAdvanced") then
		self:setOption(optName, nil);
		optName = "barVisibility";
		value = 2;

	elseif (optName == "pageBasic") then
		self:setOption(optName, nil);
		optName = "barPaging";
		value = 1;

	elseif (optName == "pageAdvanced") then
		self:setOption(optName, nil);
		optName = "barPaging";
		value = 2;

	end

	-- Process the options
	if (optName == "editGroup") then
		-- Select bar to edit.
		self:setOption("editGroup", nil);
		currentEditGroup = module.GroupNumToId(value);
		localGroupId = currentEditGroup;
		updateGroupWidgets(localGroupId);

	elseif (optName == "nextGroup") then
		-- Select next bar to edit.
		self:setOption("nextGroup", nil);
		value = module.GroupIdToNum(currentEditGroup);
		value = value + 1;
		if (value > module.maxBarNum) then
			value = 1
		end
		currentEditGroup = module.GroupNumToId(value);
		localGroupId = currentEditGroup;
		updateGroupWidgets(localGroupId);

	elseif (optName == "prvsGroup") then
		-- Select previous bar to edit.
		self:setOption("prvsGroup", nil);
		value = module.GroupIdToNum(currentEditGroup);
		value = value - 1;
		if (value < 1) then
			value = module.maxBarNum;
		end
		currentEditGroup = module.GroupNumToId(value);
		localGroupId = currentEditGroup;
		updateGroupWidgets(localGroupId);

	elseif (strsub(optName, 1, 9) == "showGroup") then
		local showGroupId = optName:match("^showGroup(%d+)$");
		localGroupId = (tonumber(showGroupId) or localGroupId);
		optName = "showGroup";

		-- Call the group's update function.
		local group = groupList[ module.GroupIdToNum(localGroupId) ];
		if ( group ) then
			group:update(optName, value);
		end

		updateGroupWidgets_ShowGroup(localGroupId);

		-- Update visibility.
		if (group) then
			CT_BarMod_UpdateGroupVisibility(localGroupId);
		end

		-- Update key binding override
		if (group) then
			if (
					localGroupId == module.actionBarId or
					localGroupId == 2 or  -- CT Bar 3
					localGroupId == 3 or  -- CT Bar 4
					localGroupId == 4 or  -- CT Bar 5
					localGroupId == 5     -- CT Bar 6
				) then
				module.setActionBindings();
			end
		end

	elseif (strsub(optName, 1, 11) == "orientation") then
		local orientGroupId = optName:match("^orientation(%d+)$");
		localGroupId = (tonumber(orientGroupId) or localGroupId);
		optName = "orientation";

		if (orientGroupId == nil) then
			-- User changed orientation in the options window,
			-- rather than right clicking on the bar's edge.

			-- Translate drop down menu index value into
			-- the string values the rest of the addon uses.
			if (value == 2) then
				value = "DOWN";
			else
				value = "ACROSS";
			end

			-- Clear the non-group specific option.
			self:setOption(optName, nil);

			-- Assign the value to the group specific option.
			self:setOption(optName .. localGroupId, value);

			return;
		end

		-- Call the group's update function.
		local group = groupList[ module.GroupIdToNum(localGroupId) ];
		if ( group ) then
			group:update(optName, value);
		end

		-- Changing orientation affects two widgets.
		updateGroupWidgets_Orientation(localGroupId);
		updateGroupWidgets_Columns(localGroupId);

	elseif (
		-- These are the options that are in the Bar
		-- Options section. We use non-group specific
		-- options in that section and then update
		-- the group specific options here.
		optName == "barScale" or
		optName == "barSpacing" or
		optName == "orientation" or
		optName == "barFlipHorizontal" or
		optName == "barFlipVertical" or
		optName == "barNumToShow" or
		optName == "barColumns" or

		optName == "barOpacity" or
		optName == "barFaded" or
		optName == "barFadedCombat" or
		optName == "barMouseover" or

		optName == "barVisibility" or
		optName == "barHideInPetBattle" or
		optName == "barHideInVehicle" or
		optName == "barHideInOverride" or
		optName == "barHideInCombat" or
		optName == "barHideNotCombat" or
		optName == "barCondition" or

		optName == "barPaging" or
		optName == "pageAltKey" or
		optName == "pageCtrlKey" or
		optName == "pageShiftKey" or
		optName == "pageCondition"

	) then
		local group = groupList[ module.GroupIdToNum(localGroupId) ];

		-- Can't clear non-group specific option for color swatches,
		-- because the functions in CT_Library access the option's value
		-- to determine the current color for the color swatch.

		-- Clear the non-group specific option.
		self:setOption(optName, nil);

		-- Assign the value to the group specific option.
		self:setOption(optName .. localGroupId, value);

		-- Call the group's update function.
		if ( group ) then
			group:update(optName, value);
		end

		-- Update some stuff on the options window.
		if (optName == "barVisibility") then
			-- Need to update visibility widgets (two checkbuttons
			-- disguised as radio buttons).
			updateGroupWidgets_Visibility(localGroupId);

		elseif (optName == "barPaging") then
			-- Need to update paging widgets (two checkbuttons
			-- disguised as radio buttons).
			updateGroupWidgets_Paging(localGroupId);

		elseif (optName == "barNumToShow") then

			-- Update the "barColumns" slider.
			-- This will include changing the slider's max value, which may affect
			-- the slider's actual value. If the slider's actual value changes when
			-- the max value is changed, then CT_Library will change the actual
			-- "barColumns" option.

			updateGroupWidgets_Columns(localGroupId);

		elseif (optName == "barColumns") then
			-- The "barColumns" option has changed, either due to the user dragging the
			-- slider, or due to the addon changing the slider's current value or maximum
			-- limit.
			-- Update the "barColumns" slider.
			updateGroupWidgets_Columns(localGroupId);

		end

		-- Update visibility.
		if (
			optName == "barVisibility" or
			optName == "barHideInPetBattle" or
			optName == "barHideInVehicle" or
			optName == "barHideInOverride" or
			optName == "barHideInCombat" or
			optName == "barHideNotCombat" or
			optName == "barCondition"
		) then
			if (group) then
				CT_BarMod_UpdateGroupVisibility(localGroupId);
			end
		end

		-- Update paging
		if (
			optName == "barPaging" or
			optName == "pageAltKey" or
			optName == "pageCtrlKey" or
			optName == "pageShiftKey" or
			optName == "pageCondition"
		) then
			module:registerPagingStateDriver(localGroupId);
		end

	elseif (optName == "disableDefaultActionBar") then
	
		-- CT_BarMod's default for this option is irrelevant. The checkbox
		-- is only visible when CT_BottomBar is loaded.
		--
		-- If the user clicks the checkbox in CT_BarMod, then that non-nil
		-- value will be provided to CT_BottomBar.
		--
		-- If the user clicks the checkbox in CT_BottomBar, then that non-nil
		-- value will be provided to CT_BarMod.
		--
		-- The only important default is the one in CT_BottomBar, since it
		-- is responsible for disabling the default main action bar.
		--
		-- When CT_BottomBar starts it will provide the current value
		-- for CT_BarMod's checkbox by updating CT_BarMod's option.

		-- Update the checkbox.
		updateWidgets_DisableActionBar();

		if (CT_BottomBar and CT_BottomBar.updateOptionFromOutside) then
			-- Set the corresponding option in CT_BottomBar.
			-- It is CT_BottomBar that is responsible for the actual
			-- disabling of the default main action bar.
			preventLoop = true;
			CT_BottomBar.updateOptionFromOutside(optName, value);
			preventLoop = nil;			
		end
	
	elseif optName == "disableDragonflightActionBar" then
		local time = GetServerTime()
		module:setOption("disableDragonflightActionBarChangedDate", time)
		if CT_BottomBar and CT_BottomBar.updateOptionFromOutside and not preventLoop then
			preventLoop = true
			CT_BottomBar.updateOptionFromOutside("disableDragonflightActionBar", value)
			preventLoop = nil
		end
		if value then
			MainMenuBar.ctBarHidden = true
			if MainMenuBar.ctBBHiddenInDragonriding then
				module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "hide" or "[overridebar] show; [vehicleui] show; hide")
			else
				module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "[bonusbar:5] show; hide" or "[bonusbar:5] show; [overridebar] show; [vehicleui] show; hide")
			end
		elseif MainMenuBar.ctBarHidden then
			MainMenuBar.ctBarHidden = nil
			module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", "[overridebar] hide; [vehicleui] hide; show")
		end

	elseif (
		optName == "hideExtraBar3" or
		optName == "hideExtraBar4" or
		optName == "hideExtraBar5" or
		optName == "hideExtraBar6"
	) then
		updateWidgets_hideExtraBars();
		module:hideExtraBars();

	elseif (optName == "clampFrames") then
		value = not not value;
		for key, obj in pairs(module.groupList) do
			obj:setClamped(value);
		end

	--elseif ( optName == "clickDirection" ) then
	--	updateClickDirection();

	--elseif ( optName == "clickIncluded" ) then
	--	updateClickDirection();
	
	elseif ( optName == "onMouseDown" ) then
		updateClickDirection();
	
	elseif (
		optName == "pullForwardChallengeMode"
		or optName == "pullForwardCovenantSanctum"
	) then
		module:pullPanelsForward(optName, value);

	elseif ( optName == "buttonLock" ) then
		module:setAttributes();

	elseif ( optName == "buttonLockKey" ) then
		module:setAttributes();

	elseif (optName == "showCTBottomBar") then
		value = not not value;
		if (value) then
			showGroupHeaders_CTBottomBar(self);
		else
			hideGroupHeaders_CTBottomBar(self);
		end

	elseif ( optName == "dragOnTop" ) then
		module:setDragOnTop(value);

	elseif ( optName == "dragTransparent" ) then
		module:setDragTransparent(value);

	elseif ( optName == "displayCount" ) then
		CT_BarMod_HideShowAllCooldowns(value);

	elseif ( optName == "skinNumber" ) then
		-- Set the skin for CT_BarMod to use
		value = value or 1;
		-- Convert dropdown menu number into an ID value.
		local id = "standard";
		local skin = module.skinsList[value];
		if (skin and skin.__CTBM__skinID) then
			id = skin.__CTBM__skinID;
		end
		module:setOption("skinID", id, CT_SKIP_UPDATE_FUNC);
		-- Assign the skin number to each of the buttons.
		module:setSkin(value);
		-- If we're not using Masque, then reskin all groups.
		if (not module:usingMasque()) then
			module:reskinAllGroups();
		end

	elseif ( optName == "skinMasque" ) then
		-- Enable/disable Masque support.
		value = not not value;
		module:enableMasque(value);
		-- If we're not using Masque, then reskin all groups.
		if (not module:usingMasque()) then
			module:reskinAllGroups();
		end

	elseif ( optName == "shiftParty" ) then
		CT_BarMod_Shift_Party_SetFlag();
		CT_BarMod_Shift_Party_Move();

	elseif ( optName == "shiftPartyOffset" ) then
		CT_BarMod_Shift_Party_SetReshiftFlag();
		CT_BarMod_Shift_Party_Move();

	elseif ( optName == "shiftFocus" ) then
		CT_BarMod_Shift_Focus_SetFlag();
		CT_BarMod_Shift_Focus_Move();

	elseif ( optName == "shiftFocusOffset" ) then
		CT_BarMod_Shift_Focus_SetReshiftFlag();
		CT_BarMod_Shift_Focus_Move();

	--elseif ( optName == "shiftMultiCast" ) then   --removed from the game in 2012
	--	CT_BarMod_Shift_MultiCast_UpdatePositions();

	elseif ( optName == "shiftPet" or optName == "shiftPetOffset") then
		CT_BarMod_Shift_Pet_UpdatePositions();

	elseif ( optName == "shiftPossess" ) then
		CT_BarMod_Shift_Possess_UpdatePositions();

	elseif ( optName == "shiftShapeshift" ) then
		CT_BarMod_Shift_Stance_UpdatePositions();

	elseif ( optName == "cooldownFontColor" ) then
		updateCooldownFontColor();

	elseif ( optName == "cooldownFontStyleNum" ) then
		local fontStyleNum = value;
		if (not fontStyleNum or fontStyleNum > #fontStyleListSorted) then
			fontStyleNum = fontDefaultStyleNum;
		end
		local fontStyleName = fontStyleListSorted[fontStyleNum];
		module:setOption("cooldownFontStyleName", fontStyleName);
		updateCooldownFont();

	elseif ( optName == "cooldownFontSize" ) then
		updateCooldownFont();

	elseif ( optName == "cooldownFontTypeNum" ) then
		local fontTypeNum = value;
		if (not fontTypeNum or fontTypeNum > #fontTypeListSorted) then
			fontTypeNum = fontDefaultTypeNum;
		end
		local fontTypeName = fontTypeListSorted[fontTypeNum];
		module:setOption("cooldownFontTypeName", fontTypeName);
		updateCooldownFont();
				
	elseif (optName == "disableIconIntro" ) then
		module.suppressActionBarController(value)
		
	elseif (optName == "newZoneAbilities" ) then
		module.controlZoneAbilityFrame(value)

	elseif ( optName == "init" ) then
		-- Convert the skin ID into a dropdown menu number.
		local skinID = module:getOption("skinID") or "standard";
		local skinNumber = 1;
		for i, skin in ipairs(module.skinsList) do
			if (skin.__CTBM__skinID == skinID) then
				skinNumber = i;
				break;
			end
		end
		module:setOption("skinNumber", skinNumber, CT_SKIP_UPDATE_FUNC);
		-- Assign the skin number to each button.
		module:setSkin(skinNumber);
		-- Reskin the buttons
		if (module:usingMasque()) then
			-- Enable Masque (and reskin the Masque groups)
			module:enableMasque(true);
		else
			-- Reskin the CT_BarMod groups
			module:reskinAllGroups();
		end
		
		module:setAttributes();
		module.setActionBindings();
		module:hideExtraBars();

		updateCooldownFont();
		updateGroups();
		updateGroupWidgets(localGroupId);

		module:setDragOnTop(module:getOption("dragOnTop"));
		module:setDragTransparent(module:getOption("dragTransparent"));

		-- Frame to watch for events
		local frame = CT_BarMod_Frame;
		frame:SetScript("OnEvent", CT_BarMod_OnEvent);
		frame:RegisterEvent("PLAYER_REGEN_ENABLED");
		frame:RegisterEvent("PLAYER_REGEN_DISABLED");
		frame:RegisterEvent("PLAYER_ENTERING_WORLD");
		frame:Show();

		CT_BarMod_Shift_Init();
		
		-- hiding the main bar from WoW 10.0 onwards
		if module:getGameVersion() >= 10 then
			if CT_BottomBar and CT_BottomBar.updateOptionFromOutside then
				local t1, t2 = module:getOption("disableDragonflightActionBarChangedDate"), CT_BottomBar:getOption("disableDragonflightActionBarChangedDate")
				preventLoop = true
				if (t1 and t2 and t1 > t2) or (t1 and not t2) then
					CT_BottomBar:setOption("disableDragonflightActionBar", module:getOption("disableDragonflightActionBar"))
				elseif (t1 and t2 and t2 < t1) or (t2 and not t1) then
					module:setOption("disableDragonflightActionBar", CT_BottomBar:getOption("disableDragonflightActionBar"))
				end
				preventLoop = nil
			end
			if module:getOption("disableDragonflightActionBar") then
				MainMenuBar.ctBarHidden = true
				if MainMenuBar.ctBBHiddenInDragonriding then
					RegisterAttributeDriver(MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "hide" or "[overridebar] show; [vehicleui] show; hide")
				else
					RegisterAttributeDriver(MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "[bonusbar:5] show; hide" or "[bonusbar:5] show; [overridebar] show; [vehicleui] show; hide")
				end
			end
		end
	end

	-- Clear edit box focus and highlight.
	-- Calling it here will ensure the focus is removed regardless of
	-- which option the user changes.
	if (groupFrame) then
		groupFrame.conditionEB:ClearFocus();
		groupFrame.conditionEB:HighlightText(0, 0);

		groupFrame.pageEB:ClearFocus();
		groupFrame.pageEB:HighlightText(0, 0);
	end
end
