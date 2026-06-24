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
-- Retail/Classic API differences

local SaveBindings = SaveBindings or AttemptToSaveBindings;   -- Retail vs Classic

-- End Local Copies
--------------------------------------------

local actionButtonList = module.actionButtonList;
local groupList = module.groupList;

-- Tooltip for figuring out spell name
local TOOLTIP = CreateFrame("GameTooltip", "CT_BarModTooltip", nil, "GameTooltipTemplate");
local TOOLTIP_TITLELEFT = _G.CT_BarModTooltipTextLeft1;
local TOOLTIP_TITLERIGHT = _G.CT_BarModTooltipTextRight1;

--------------------------------------------
-- Global variables for use with the game's key binding window.

do
	local count = 1
	for bar = 1, module.maxBarNum do
		_G["BINDING_HEADER_CT_BarMod_Bar" .. bar] = "CT_BarMod Bar" .. bar;
		for button = 1, 12 do
			_G["BINDING_NAME_CLICK CT_BarModActionButton" .. count .. ":Button31"] = "Bar " .. bar .. " Button " .. button;
			count = count + 1;
		end
	end
end

--------------------------------------------
-- Miscellaneous

local hasCachedBindingKeys, cachedBindingKey1, cachedBindingKey2 = {}, {}, {}
module.getBindingKey = function(buttonId)
	-- Returns key(s) currently bound to the CT_BarMod button number.
	-- Eg. "1", "SHIFT-A", etc.
	
	if (hasCachedBindingKeys[buttonId]) then
		return cachedBindingKey1[buttonId], cachedBindingKey2[buttonId]
	else
		local key1, key2 = GetBindingKey("CLICK CT_BarModActionButton" .. buttonId .. ":Button31");
		hasCachedBindingKeys[buttonId], cachedBindingKey1[buttonId], cachedBindingKey2[buttonId] = true, key1, key2
		return key1, key2
	end
end

local function wipeBindingCache()
	wipe(hasCachedBindingKeys);
end

-- Key Bindings Purger
--[[module:regEvent("UPDATE_BINDINGS", function()
	local GetBindingAction = GetBindingAction;
	local strmatch = strmatch;
	local key, action;
	for buttonId, object in pairs(actionButtonList) do
		key = module:getOption("BINDING-" .. buttonId);
		if ( key ) then
			action = GetBindingByKey(key);
			if ( action and tostring(buttonId) ~= strmatch(action,"^CLICK CT_BarModActionButton(%d+)") ) then
				module:setOption("BINDING-" .. buttonId, nil);
			end
		end
	end
end);]]

--------------------------------------------
-- Buttons handler

local buttonsFrame, selectedButton;
local buttonsMode;
local buttonsModes = {};
local buttonsFuncs = {};
local buttonsStart, buttonsEnd;

local function buttonsRegisterMode(mode, name, startFunc, endFunc)
	tinsert(buttonsModes, { mode = mode, name = name, startFunc = startFunc, endFunc = endFunc });
end

local function buttonsSetMode(mode)
	local found;

	if (buttonsEnd) then
		buttonsEnd();
	end

	for i, data in ipairs(buttonsModes) do
		if (data.mode == mode) then
			found = data;
			break;
		end
	end
	if (not found) then
		found = buttonsModes[1];
	end

	buttonsMode = found.mode;
	buttonsStart = found.startFunc;
	buttonsEnd = found.endFunc;

	buttonsStart();
	buttonsFrame:GetScript("OnShow")(buttonsFrame);
end

local function getSpellName(actionId, actionMode, noRank)
	local spellName, spellRank;

	if (HasAction(actionId)) then
		-- Get information about the action assigned to the button.
		local spellType, id, subType, spellID = GetActionInfo(actionId);

		-- Try to determine the spell name and rank.
		if (spellType == "spell" or spellType == "companion") then
			if (spellID) then
				spellName = CT_Library.getSpellName(spellID);	-- shared helper (rank is deprecated/nil in the modern API)
			end
		end
		if (not spellName or spellName == "") then
			-- Scan the tooltip for the spell name and rank.
			-- We must set the tooltip owner each time in case it gets
			-- cleared when attempting to call SetAction() for a spell
			-- the player doesn't know.
			TOOLTIP:SetOwner(WorldFrame, "ANCHOR_NONE");
			TOOLTIP:ClearLines();
			TOOLTIP:SetAction(actionId);
			-- Spell name and rank should be on the first line of the tooltip.
			spellName = TOOLTIP_TITLELEFT:GetText();
			spellRank = TOOLTIP_TITLERIGHT:GetText();
		end
		if (spellName and spellName ~= "") then
			-- We have a spell name.
			-- Format the rank.
			if (spellRank) then
				if (noRank) then
					spellRank = nil;
				else
					spellRank = spellRank:match("(%d+)$");
					if (spellRank) then
						spellRank = " (R" .. spellRank .. ")";
					end
				end
			end
		else
			-- Still don't have a spell name.
			spellRank = nil;

			-- Try some other things.
			spellName = GetActionText(actionId);
			if (not spellName or spellName == "") then
				if (spellType == "macro") then
					spellName = GetMacroInfo(id);
				end
			end
		end
	elseif (actionMode == "cancel") then
		spellName = CANCEL or "Cancel"; -- LEAVE_VEHICLE or "Leave Vehicle";
	elseif (actionMode == "leave") then
		spellName = LEAVE_VEHICLE or "Leave Vehicle";
	end

	-- If we still don't have a spell name, then return "<None>".
	if (not spellName or spellName == "") then
		return "|c00FF2222<|r|c00FFFFFFNone|r|c00FF2222>|r";
	end

	-- Return the spell name with rank, or just the spell name.
	if (spellRank) then
		return spellName .. spellRank;
	end

	return spellName;
end

local function buttonsUpdateEntry(index, object, isGroup, group)
	-- Update an entry in the buttons list.
	--   index == Display object index number (1 to 13).
	--   object == Button or group object.
	--   isGroup == true if object is a group object.
	--   group == group object
	local displayObj = buttonsFrame[tostring(index)];
	if ( not displayObj ) then
		module:print(index, object, isGroup);
	end
	if ( isGroup ) then
		-- Display section heading.
		if ( object.hiddenDisplay ) then
			displayObj.header:SetText("+");
		else
			displayObj.header:SetText("-");
		end

		local spell = displayObj.spell;
		spell:SetFontObject(GameFontNormalLarge);
		spell:SetText(format("|c00FFD200%s|r", object.fullName));
--		spell:SetText(object.fullName);
		displayObj.binding:SetText("");
		displayObj.buttonId = -1;
		displayObj.actionId = -1;
		displayObj.actionMode = "";
		displayObj.group = object;
		displayObj.isGroup = true;
	else
		-- Display button details.
		displayObj.header:SetText("");

		local actionId = object.actionId;
		local actionMode = object.actionMode;
		local buttonId = object.buttonId;
		local spell = displayObj.spell;
		spell:SetFontObject(ChatFontNormal);
		spell:SetText(format("|c00FFD200%3d|r %s", object.buttonNum, getSpellName(actionId, actionMode)));

		if (buttonsFuncs.detailFunc) then
			displayObj.binding:SetText( (buttonsFuncs.detailFunc)(buttonId, actionId) );
		else
			displayObj.binding:SetText( "" );
		end

		displayObj.buttonId = buttonId;
		displayObj.actionId = actionId;
		displayObj.actionMode = actionMode;
		displayObj.buttonNum = object.buttonNum;
		displayObj.group = group;
		displayObj.isGroup = nil;
	end
	displayObj:Show();
	if ( index == 13 ) then
		return true;
	end
end

local function buttonsUpdateList()
	-- Update the button list.
	local offset = FauxScrollFrame_GetOffset(CT_BarModOptionsKeyBindingsScrollFrame);
	local index = 0;
	local objects = 0;
	local shallBreak;
	for gnum, group in ipairs(groupList) do
		objects = group.objects;
		if ( objects ) then
			index = index + 1;
			if ( index > offset ) then
				-- Display the section heading.
				if ( buttonsUpdateEntry(index - offset, group, true, group) ) then
					-- We've now displayed all we can.
					break;
				end
			end
			-- If the section details are not hidden...
			if ( not group.hiddenDisplay ) then
				-- Display the buttons in the section.
				for key, button in ipairs(objects) do
					index = index + 1;
					if ( index > offset ) then
						if ( buttonsUpdateEntry(index - offset, button, false, group) ) then
							-- We've now displayed all we can.
							shallBreak = true;
							break;
						end
					end
				end
				if ( shallBreak ) then
					-- We've now displayed all we can.
					break;
				end
			end
		end
	end

	-- Hide all other entries
	for i = index + 1, 13 do
		buttonsFrame[tostring(i)]:Hide();
	end
end

module.keybindings_buttonsUpdateList = function()
	local frame = CT_BarModOptionsKeyBindingsScrollFrame;
	if (frame and frame:IsVisible()) then
		buttonsUpdateList();
	end
end

local prevOffset;

local function buttonsUpdateScroll()
	-- Update the buttons scroll frame.
	local scrollFrame = CT_BarModOptionsKeyBindingsScrollFrame;

	if ( selectedButton ) then
		scrollFrame:SetVerticalScroll(prevOffset or 0);
		return;
	end

	-- Get number of entries in the list.
	local numEntries = 0;
	local objects = 0;
	for gnum, value in pairs(groupList) do
		numEntries = numEntries + 1;
		if ( not value.hiddenDisplay ) then
			objects = value.objects;
			if ( objects ) then
				for k, v in ipairs(objects) do
					numEntries = numEntries + 1;
				end
			end
		end
	end

	-- Update the display.
	prevOffset = scrollFrame:GetVerticalScroll();
	FauxScrollFrame_Update(CT_BarModOptionsKeyBindingsScrollFrame, numEntries, 13, 25);
	buttonsUpdateList();

--	_G[scrollFrame:GetName().."ScrollChildFrame"]:SetHeight(scrollFrame:GetHeight());
end

local function buttonsUpdateSelection(isConflict)
	-- Update the current selection display.
	local tempObj;
	local buttonId;
	if (selectedButton) then
		buttonId = selectedButton.buttonId;
	end
	for i = 1, 13 do
		tempObj = buttonsFrame[tostring(i)];
		if ( tempObj.buttonId ~= buttonId ) then
			tempObj.selected = false;
			if ( tempObj:IsMouseOver() ) then
				--tempObj:GetScript("OnEnter")(tempObj);
				tempObj.background:SetVertexColor(1, 1, 1, 0.2);

			else
				--tempObj:GetScript("OnLeave")(tempObj);
				tempObj.background:SetVertexColor(1, 1, 1, 0);
			end
		else
			tempObj.selected = true;
			if ( isConflict ) then
				tempObj.background:SetVertexColor(1, 0.45, 0.1, 0.6);
			else
				tempObj.background:SetVertexColor(1, 0.87, 0.3, 0.4);
			end
		end
	end
end

local function buttonsClearSelection()
	-- Clear the current selection.
	selectedButton = nil;
	buttonsUpdateSelection();
end

local function buttonSetTooltip(self, ...)
	-- self == a button frame
	if (not selectedButton) then
		if (self.buttonId == -1) then
			-- A heading
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("Bar " .. self.group.num, 1, 1, 1);
			if (self.group.hiddenDisplay) then
				GameTooltip:AddLine("Left-click to expand.\nRight-click to expand all.");
			else
				GameTooltip:AddLine("Left-click to collapse.\nRight-click to collapse all.");
			end
			GameTooltip:Show();
		else
			if (buttonsFuncs.buttonTooltip) then
				buttonsFuncs.buttonTooltip(self, ...);
			else
				GameTooltip:Hide();
			end
		end
	else
		if (buttonsFuncs.buttonTooltip) then
			buttonsFuncs.buttonTooltip(self, ...);
		else
			GameTooltip:Hide();
		end
	end
end

local function buttonToggleHeading(obj, all)
	local buttonId;
	if (obj) then
		buttonId = obj.buttonId;
	end
	if ( buttonId == -1 ) then
		-- Group heading
		if ( not selectedButton ) then
			-- Nothing currently selected.
			if (all) then
				-- Expand or collapse all headings
				local hide = not obj.group.hiddenDisplay;
				for gnum, group in ipairs(groupList) do
					group.hiddenDisplay = hide;
				end
			else
				-- Toggle the display of the group's details
				obj.group.hiddenDisplay = not obj.group.hiddenDisplay;
			end
			buttonsUpdateScroll();
		end
	end
end

local function buttonsSelectButton(obj)
	-- Select the specified object.
	-- obj == a button frame
	local buttonId;
	if (obj) then
		buttonId = obj.buttonId;
	end
	if ( buttonId == -1 ) then
		-- Group heading
		-- Do nothing.
		return nil;
	end
	selectedButton = obj;
	buttonsUpdateSelection();
	return true;
end

--------------------------------------------
-- Key Bindings Handler

local bindingNum = 1;  -- Binding number 1 or 2 for the buttons

local function bindingsDetailText(buttonId, actionId)
	-- Get text to display in a section detail entry of the button list.
	local text1, text2;
	-- text1 = module:getOption("BINDING-"..buttonId) or "";
	text1, text2 = module.getBindingKey(buttonId);
	if (bindingNum == 2) then
		text1 = text2;
	end
	return (text1 or "") .. "  (" .. bindingNum .. ")";
end

local function bindingsAssign(buttonId, key)
	-- Assign the specified key binding to the button associated with the specified button id.
	if (InCombatLockdown()) then
		return;
	end
	-- Get the CT_BarMod button object associated with the specified button id.
	local obj = actionButtonList[buttonId];
	if ( obj ) then
		--module:setOption("BINDING-" .. buttonId, key);
		-- Bind the key to the action.
		obj:setBinding(key);
		SaveBindings(GetCurrentBindingSet());
	end
end

local function bindingsDelete(buttonId)
	-- Delete the key binding of the button associated with the specified button number.
	if (InCombatLockdown()) then
		return;
	end
	-- Get the CT_BarMod button object associated with the specified button id.
	local obj = actionButtonList[buttonId];
	if ( obj ) then
		--module:setOption("BINDING-" .. buttonId, nil);
		-- Get the current key binding associated with the button id.
		local currKey1, currKey2 = module.getBindingKey(buttonId);
		if (bindingNum == 2) then
			currKey1 = currKey2;
		end
		if (currKey1) then
			-- Delete the key binding
			obj:setBinding(currKey1, true);
			SaveBindings(GetCurrentBindingSet());
		end
	end
end

local attemptedKey;

local function bindingsSetMode(mode, arg1, arg2)
	local obj = selectedButton;

	if (mode == 1) then
		-- Ask user to select a button.
		buttonsFrame:EnableKeyboard(false);
		buttonsFrame.instruction:SetText(
			"Left-click a button in the list below\nto change its key binding.\nRight-click a button to see the other binding.");

	elseif (mode == 2) then
		-- Ask user to press a key.
		--local currKey1 = module:getOption("BINDING-" .. selectedButton.buttonId);
		local currKey1, currKey2 = module.getBindingKey(selectedButton.buttonId);
		buttonsFrame:EnableKeyboard(true);
		if ( (bindingNum == 1 and currKey1) or (bindingNum == 2 and currKey2) ) then
			buttonsFrame.instruction:SetText(format(
				"Press the key to bind to the button\n|c00FFFFFF%s|r\n|c00FF0000Right-Click|r to unbind / |c00FF0000Escape|r to cancel.", getSpellName(obj.actionId, obj.actionMode)));

			obj.tooltip = {"Update binding", "Press the key to bind.\nRight-click to unbind.\nPress Esc to cancel."};
		else
			buttonsFrame.instruction:SetText(format(
				"Press the key to bind to the button\n|c00FFFFFF%s|r\nPress |c00FF0000Escape|r to cancel.", getSpellName(obj.actionId, obj.actionMode)));

			obj.tooltip = {"New binding", "Press the key to bind.\nPress Esc to cancel."};
		end

	elseif (mode == 3) then
		-- Ask user to override an existing binding.
		-- arg1 == The action that was bound to the key.
		-- arg2 == The key the user attempted to bind.
		local bindingKey = GetBindingText(arg1, "BINDING_NAME_");
		local buttonId = bindingKey:match("^CLICK CT_BarModActionButton(%d+)");
		if ( buttonId ) then
			local button = actionButtonList[tonumber(buttonId)];
			if ( button ) then
				bindingKey = format("|c00FFD200%d|r |c00FFFFFF%s|r", buttonId, getSpellName(button.actionId, button.actionMode, false));
				local num = module.GroupIdToNum(button.groupId);
				local group = groupList[num];
				if ( group ) then
					bindingKey = bindingKey .. "\non " .. group.fullName .. ".";
				end
			else
				bindingKey = format("|c00FFD200%d|r |c00FFFFFF%s|r", buttonId, getSpellName(nil, nil, false));
			end
		end
		buttonsFrame.instruction:SetText(format(
			"The key |c00FFFFFF%s|r is used by\n|c00FFFFFF%s|r\n" ..
			"|c0000FF00Enter|r to Overwrite / |c00FF0000Escape|r to Cancel.",
			arg2, bindingKey));

		obj.tooltip = {"Binding exists", "Press Enter to overwrite.\nPress Esc to cancel."};
	end

	buttonsUpdateList();
end

local function bindingsCancel()
	attemptedKey = nil;
	buttonsClearSelection();
	bindingsSetMode(1);  -- Ask user to select a button.
end

local function bindingsSelect(obj)
	-- obj == a button frame
	if (selectedButton) then
		bindingsCancel();
	end
	attemptedKey = nil;
	buttonsSelectButton(obj);
	if (selectedButton) then
		bindingsSetMode(2);  -- Ask user to press a key.
	else
		bindingsSetMode(1);  -- Ask user to select a button.
	end
end

local function bindingsKeyPressed(key)
	-- A key was pressed, a mouse button was pressed, or the mouse wheel was turned.
	if (
		key == "UNKNOWN" or
		key:match("[LR]?SHIFT") or
		key:match("[LR]?CTRL") or
		key:match("[LR]?ALT")
	) then
		return;
	end

	-- Convert the mouse button names
	if ( key == "LeftButton" ) then
		key = "BUTTON1";
	elseif ( key == "RightButton" ) then
		key = "BUTTON2";
	elseif ( key == "MiddleButton" ) then
		key = "BUTTON3";
	elseif ( key == "Button4" ) then
		key = "BUTTON4"
	elseif ( key == "Button5" ) then
		key = "BUTTON5"
	elseif ( key == "Button6" ) then
		key = "BUTTON6"
	elseif ( key == "Button7" ) then
		key = "BUTTON7"
	elseif ( key == "Button8" ) then
		key = "BUTTON8"
	elseif ( key == "Button9" ) then
		key = "BUTTON9"
	elseif ( key == "Button10" ) then
		key = "BUTTON10"
	elseif ( key == "Button11" ) then
		key = "BUTTON11"
	elseif ( key == "Button12" ) then
		key = "BUTTON12"
	elseif ( key == "Button13" ) then
		key = "BUTTON13"
	elseif ( key == "Button14" ) then
		key = "BUTTON14"
	elseif ( key == "Button15" ) then
		key = "BUTTON15"
	elseif ( key == "Button16" ) then
		key = "BUTTON16"
	elseif ( key == "Button17" ) then
		key = "BUTTON17"
	elseif ( key == "Button18" ) then
		key = "BUTTON18"
	elseif ( key == "Button19" ) then
		key = "BUTTON19"
	elseif ( key == "Button20" ) then
		key = "BUTTON20"
	elseif ( key == "Button21" ) then
		key = "BUTTON21"
	elseif ( key == "Button22" ) then
		key = "BUTTON22"
	elseif ( key == "Button23" ) then
		key = "BUTTON23"
	elseif ( key == "Button24" ) then
		key = "BUTTON24"
	elseif ( key == "Button25" ) then
		key = "BUTTON25"
	elseif ( key == "Button26" ) then
		key = "BUTTON26"
	elseif ( key == "Button27" ) then
		key = "BUTTON27"
	elseif ( key == "Button28" ) then
		key = "BUTTON28"
	elseif ( key == "Button29" ) then
		key = "BUTTON29"
	elseif ( key == "Button30" ) then
		key = "BUTTON30"
	elseif ( key == "Button31" ) then
		key = "BUTTON31"
	end

	-- Apply modifiers to the key name.
	if ( IsShiftKeyDown() ) then
		key = "SHIFT-"..key;
	end
	if ( IsControlKeyDown() ) then
		key = "CTRL-"..key;
	end
	if ( IsAltKeyDown() ) then
		key = "ALT-"..key;
	end

	-- Evaluate the key that was pressed.

	if ( key == "ESCAPE" ) then
		-- Cancel the attempted key binding.
		bindingsCancel();
		return;
	end

	if ( key == "BUTTON1") then
		-- Don't allow mouse button 1 to be bound.
		return;
	end

	if ( selectedButton and attemptedKey ) then
		if ( key == "ENTER" ) then
			-- Overwrite the existing key binding.
			if (not InCombatLockdown()) then
				bindingsDelete(selectedButton.buttonId);
				bindingsAssign(selectedButton.buttonId, attemptedKey);
			else
				module:print("You cannot change key bindings while in combat.");
			end
			bindingsCancel();
		end
		return;
	end

	attemptedKey = nil;

	if ( not selectedButton ) then
		-- Nothing selected.
		return;
	end

	if ( key == "BUTTON2" ) then
		-- Delete the key binding.
		if (not InCombatLockdown()) then
			bindingsDelete(selectedButton.buttonId);
		else
			module:print("You cannot change key bindings while in combat.");
		end
		bindingsCancel();
		return;
	end

	-- Check if there is already an action bound to the key.
	local currentAction = GetBindingAction(key);
	if ( currentAction and currentAction ~= "" ) then
		-- The key the user pressed is already bound.
		attemptedKey = key;  -- Remember the key that had a conflict
		buttonsUpdateSelection(true);
		bindingsSetMode(3, currentAction, attemptedKey);  -- Ask user if they want to override.
	else
		-- The key is not currently bound, so bind it.
		if (not InCombatLockdown()) then
			bindingsDelete(selectedButton.buttonId);
			bindingsAssign(selectedButton.buttonId, key);
		else
			module:print("You cannot change key bindings while in combat.");
		end
		bindingsCancel();
	end
end

local bindingsFuncs;

local function bindingsModeStart()
	if (not bindingsFuncs) then
		bindingsFuncs = {};
		bindingsFuncs.detailFunc = bindingsDetailText;
		bindingsFuncs.frameOnShow = function(self)
			bindingsCancel();
			bindingsSetMode(1);  -- Ask user to select a button.
		end
		bindingsFuncs.frameOnKeyDown = function(self, key)
			bindingsKeyPressed(key);
		end
		bindingsFuncs.buttonOnClick = function(self, button)
			if (button == "RightButton" and not selectedButton) then
				if (self.buttonId == -1) then
					-- Expand or collapse all headings
					buttonToggleHeading(self, true);
				else
					-- A button.
					-- Toggle the binding numbers.
					if (bindingNum == 1) then
						bindingNum = 2;
					else
						bindingNum = 1;
					end
					buttonsUpdateList();
				end
			elseif (button == "LeftButton") then
				if (self.buttonId == -1) then
					-- Expand/collapse this heading
					buttonToggleHeading(self, false);
				else
					-- Select button
					bindingsSelect(self);
				end
			end
		end
		bindingsFuncs.buttonOnMouseDown = function(self, button)
			bindingsKeyPressed(button);  -- Process the button
		end
		bindingsFuncs.buttonTooltip = function(self, ...)
			if (not selectedButton) then
				local nextBinding;
				if (bindingNum == 2) then
					nextBinding = 1;
				else
					nextBinding = 2;
				end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText("Bar " .. self.group.num .. " Button " .. self.buttonNum, 1, 1, 1);
				GameTooltip:AddLine("Left-click to change the binding.\nRight-click to see binding " .. nextBinding .. ".");
				GameTooltip:Show();
			else
				local self = selectedButton;
				if (self.tooltip) then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText(self.tooltip[1], 1, 1, 1);
					GameTooltip:AddLine(self.tooltip[2]);
					GameTooltip:Show();
				else
					GameTooltip:Hide();
				end
			end
		end
		bindingsFuncs.scrollOnMouseWheel = function(self, delta)
			if ( buttonsFrame:IsKeyboardEnabled() ) then
				if ( delta > 0 ) then
					bindingsKeyPressed("MOUSEWHEELUP");
				else
					bindingsKeyPressed("MOUSEWHEELDOWN");
				end
				return false;
			end
			return true;
		end
	end
	buttonsFuncs = bindingsFuncs;
end

local function bindingsModeEnd()
	bindingsCancel();
	buttonsFrame:EnableKeyboard(false);
end

--------------------------------------------
-- Flyout

local flyoutFuncs;
local flyoutDirections = {"UP", "RIGHT", "DOWN", "LEFT"};

local function flyoutModeStart()
	if (not flyoutFuncs) then
		flyoutFuncs = {};

		flyoutFuncs.detailFunc = function(buttonId, actionId)
			local actionType = GetActionInfo(actionId);
--			if (actionType ~= "flyout") then
--				return "";
--			end
			local direction = module:getOption("flyoutDirection" .. buttonId) or "UP";
			return direction;
		end

		flyoutFuncs.frameOnShow = function(self)
			self.instruction:SetText("Click a button below to change the direction\nin which the flyout bar will open.\nThis will only affect buttons that have\nabilities with flyout bars.");
		end

		flyoutFuncs.buttonOnClick = function(self, button)
			if (button == "RightButton" and not selectedButton) then
				if (self.buttonId == -1) then
					-- Expand or collapse all headings
					buttonToggleHeading(self, true);
					return;
				end
			elseif (button == "LeftButton") then
				if (self.buttonId == -1) then
					-- Expand/collapse this heading
					buttonToggleHeading(self, false);
					return;
				end
			end

			local actionType = GetActionInfo(self.actionId);
--			if (actionType ~= "flyout") then
--				return;
--			end
			local direction = module:getOption("flyoutDirection" .. self.buttonId) or "UP";
			local found = 0;
			for k, v in ipairs(flyoutDirections) do
				if (v == direction) then
					found = k;
					break;
				end
			end
			found = found + 1;
			if (found > #flyoutDirections) then
				found = 1;
			end
			module:setOption("flyoutDirection" .. self.buttonId, flyoutDirections[found]);
			buttonsUpdateList();

			local obj = actionButtonList[self.buttonId];
			if (obj) then
				if (not InCombatLockdown()) then
					obj.button:SetAttribute("flyoutDirection", module:getOption("flyoutDirection" .. self.buttonId) or "UP");
				else
					module.needSetAttributes = true;
				end
				obj:updateFlyout();
				if ((SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == obj.button) or GetMouseFoci()[1] == obj.button) then
					if (not InCombatLockdown()) then
						SpellFlyout:Hide();
					end
				end
			end
		end

		flyoutFuncs.buttonTooltip = function(self)
			if (not selectedButton) then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText("Bar " .. self.group.num .. " Button " .. self.buttonNum, 1, 1, 1);
				GameTooltip:AddLine("Click to change the direction\nof the flyout bar.");
				GameTooltip:Show();
			else
				GameTooltip:Hide();
			end
		end
	end
	buttonsFuncs = flyoutFuncs;
end

local function flyoutModeEnd()

end


--------------------------------------------
-- Override default action bar key bindings.

-- Set or clear the overrride bindings for the action bar.
local function setActionBindings(event)	
	if (InCombatLockdown()) then
		module.needSetActionBindings = true;
		return;
	end
	
	-- clear the cache earlier in this file to ensure a fresh set of override bindings
	wipeBindingCache()
	
	-- These CT_BarMod groups correspond with action bars in the default UI.
	-- Each of the buttons in these groups is associated with an action name
	-- (eg. "ACTIONBUTTON1", "MULTIACTIONBAR1BUTTON1", etc).
	local groupIds = {2, 3, 4, 5, module.actionBarId};

	for i, groupId in ipairs(groupIds) do
		local groupNum = module.GroupIdToNum( groupId );
		local groupObj = groupList[groupNum];
		if (groupObj) then
			local owner = groupObj.frame;
			local showBar = module:getOption("showGroup" .. groupId) ~= false;
			local useDefault;  -- Assign override bindings to CT_BarMod buttons using default UI's keys.
			--local overrideActions;  -- Assign override bindings to actions using CT_BarMod's keys.   -- removed in 8.3.0.3, see comment below

			-- Clear the current override bindings for this bar.
			ClearOverrideBindings(owner);

			if (groupId == module.actionBarId) then
				useDefault = module:getOption("actionBindings") ~= false;
				if (
					event ~= "UNIT_EXITED_VEHICLE"						-- special case, while exiting the vehicle the secure frame may not have updated yet
					and (
						event == "UNIT_ENTERING_VEHICLE"				-- special case, some world quests activate combat lockdown before the secure frame registers being inside the vehicleUI
						or CT_BarMod_SecureFrame:GetAttribute("hasPetBattle") 
						or CT_BarMod_SecureFrame:GetAttribute("hasOverrideBar") 
						or CT_BarMod_SecureFrame:GetAttribute("hasVehicleUI")
					)
				) then
					-- We are in a pet battle or the override bar is showing
					-- 1. Leave the main action bar's override bindings cleared.
					useDefault = false;
				
					--[[ Removing in 8.3.0.3, see comment further below
						-- 2. Assign override bindings to the actions "ACTIONBUTTON1"
						--    through "ACTIONBUTTON12" using the keys that are currently
						--    assigned to the buttons on CT_BarMod's action bar (bar 12).
						--overrideActions = true;
					--]]
				end
			elseif (groupId == 2) then
				useDefault = module:getOption("bar3Bindings") ~= false;
			elseif (groupId == 3) then
				useDefault = module:getOption("bar4Bindings") ~= false;
			elseif (groupId == 4) then
				useDefault = module:getOption("bar5Bindings") ~= false;
			elseif (groupId == 5) then
				useDefault = module:getOption("bar6Bindings") ~= false;
			end
			
			if (showBar) then
				local buttonObjs = groupObj.objects;
				local action;
				local baseNum = (groupNum - 1) * 12;
				for buttonNum = 1, 12 do
					local buttonObj = buttonObjs[buttonNum];
					-- Get the action name associated with this button (eg. "ACTIONBUTTON1")
					local action = buttonObj.actionName .. buttonNum;
					if (useDefault) then
						-- Get the key(s) currently assigned to the action.
						local key1, key2 = GetBindingKey(action);
						-- Assign override binding clicks to the CT_BarMod button.
						if (key1) then
							SetOverrideBinding(owner, false, key1, action);
						end
						if (key2) then
							SetOverrideBinding(owner, false, key2, action);
						end
					end
					-- if (overrideActions) then -- conditional removed in 8.3.0.3:
								     -- previously this was only used going into a pet battle or vehicle,
								     -- but now its always used to take advantage of Blizzard's secure implementation of console variable ActionButtonUseKeyDown
					do
						-- Get the key(s) currently assigned to the CT_BarMod button.
						local key1, key2 = module.getBindingKey(baseNum + buttonNum );
						-- Assign override bindings to the action.
						if (key1) then
							SetOverrideBinding(owner, false, key1, action);
						end
						if (key2) then
							SetOverrideBinding(owner, false, key2, action);	
						end
					end
				end
			end
		end
	end

	module.needSetActionBindings = false;
end


---------------------------------------------
-- Key Bindings options frame related

local mouseoverButton

local keyBindingTemplate = {
	"font#r:l:-2:0#v:GameFontNormalLarge#i:header#1:0.82:0:l",
	"font#r:-5:0#v:GameFontNormal#i:binding##1:0.82:0:r",
	"font#l:5:0#r:l:binding#v:ChatFontNormal#i:spell##1:1:1:l",
	"texture#all#i:background#1:1:1:1:1",

	["onload"] = function(self)
		self.background:SetVertexColor(1, 1, 1, 0);
		-- Use a full, valid font path: the bare "FRIZQT__.TTF" is rejected in Midnight ("file not found").
		-- Reuse the header's inherited font (locale-correct), falling back to STANDARD_TEXT_FONT.
		local fontPath = self.header:GetFont() or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF";
		self.header:SetFont(fontPath, 20, "OUTLINE");  -- "OUTLINE, MONOCHROME");
		self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	end,
	["onenter"] = function(self)
		mouseoverButton = self;
		buttonSetTooltip(self);
		if ( self.selected ) then
			return;
		end
		self.background:SetVertexColor(1, 1, 1, 0.2);
	end,
	["onleave"] = function(self)
		GameTooltip:Hide();
		if ( self.selected ) then
			return;
		end
		self.background:SetVertexColor(1, 1, 1, 0);
	end,
	["onclick"] = function(self, button)
		-- OnClick occurs after OnMouseDown
		if (self.ignoreClick) then
			self.ignoreClick = false;
			return;
		end
		-- If the object clicked is not the currently selected object...
		if ( selectedButton ~= self ) then
			-- Nothing currently selected, or user clicked an object other than the selected one.
			-- Select the object (or toggle a section heading).
			if (buttonsFuncs.buttonOnClick) then
				buttonSetTooltip(self);
				(buttonsFuncs.buttonOnClick)(self, button);
				buttonSetTooltip(self);
			end
		end
	end,
	["onmousedown"] = function(self, button)
		-- OnMouseDown occurs before OnClick
		-- If the mouse button was pressed on the currently selected object...
		if ( selectedButton == self ) then
			if (buttonsFuncs.buttonOnMouseDown) then
				buttonSetTooltip(self);
				(buttonsFuncs.buttonOnMouseDown)(self, button);
				buttonSetTooltip(self);
				self.ignoreClick = true;
			end
		end
	end
};

local function keyBindingOnLoad(self)
	-- Key bindings options frame has loaded.

	buttonsFrame = self;
	module:regEvent("UPDATE_BINDINGS", buttonsUpdateList);
	module:regEvent("ACTIONBAR_SLOT_CHANGED", buttonsUpdateList);
	module:regEvent("UPDATE_BONUS_ACTIONBAR", buttonsUpdateList);

	local yoffset = self:GetTop() - self["1"]:GetTop();

	local scrollFrame = CreateFrame("ScrollFrame", "CT_BarModOptionsKeyBindingsScrollFrame",
		self, "FauxScrollFrameTemplate");
	scrollFrame:SetPoint("TOPLEFT", self, 0, -yoffset);
	scrollFrame:SetPoint("BOTTOMRIGHT", self, -19, 0);

	local tex = scrollFrame:CreateTexture(scrollFrame:GetName() .. "Track", "BACKGROUND");
	tex:SetColorTexture(0, 0, 0, 0.3);
	tex:ClearAllPoints();
	tex:SetPoint("TOPLEFT", _G[scrollFrame:GetName().."ScrollBar"], -1, 17);
	tex:SetPoint("BOTTOMRIGHT", _G[scrollFrame:GetName().."ScrollBar"], 5, -17);

	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 25, buttonsUpdateScroll);
	end);

	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local default;
		if (buttonsFuncs.scrollOnMouseWheel) then
			default = (buttonsFuncs.scrollOnMouseWheel)(self, delta);
		else
			default = true;
		end
		if (default) then
			ScrollFrameTemplate_OnMouseWheel(self, delta);
		end
	end);

	buttonsRegisterMode("bindings", "Key bindings", bindingsModeStart, bindingsModeEnd);
	buttonsRegisterMode("flyout", "Flyout bar direction", flyoutModeStart, flyoutModeEnd);

	do
		local function buttonsOptionDropdownClick(self)
			local dropdown = UIDROPDOWNMENU_OPEN_MENU;
			-- 7.0.3
			if not dropdown then
				dropdown = UIDROPDOWNMENU_INIT_MENU
			end
			if ( dropdown ) then
				local value = self.value;
				local option = dropdown.option;
				UIDropDownMenu_SetSelectedValue(dropdown, value);
				if ( option ) then
					dropdown.object:setOption(option, value);
				end
				local data = buttonsModes[value];
				buttonsSetMode(data.mode);
			end
		end

		local dropdownEntry = {};
		UIDropDownMenu_Initialize(CT_BarModDropButtonOptions, function()
			for i = 1, #buttonsModes, 1 do
				dropdownEntry.text = buttonsModes[i].name;
				dropdownEntry.value = i;
				dropdownEntry.checked = nil;
				dropdownEntry.func = buttonsOptionDropdownClick;
				UIDropDownMenu_AddButton(dropdownEntry);
			end
		end);
	end

	UIDropDownMenu_SetSelectedValue(CT_BarModDropButtonOptions, 1);

	buttonsSetMode();
end

local function keyBindingOnShow(self)
	-- Key bindings options frame has been shown.

	if (buttonsFuncs.frameOnShow) then
		(buttonsFuncs.frameOnShow)(self);
	end
	buttonsUpdateScroll();
end

local function keyBindingOnKeyDown(self, key)
	-- Key bindings options frame: Key was pressed down.

	if (buttonsFuncs.frameOnKeyDown) then
		if (mouseoverButton:IsMouseOver()) then
			buttonSetTooltip(mouseoverButton);
		else
			GameTooltip:Hide();
		end
		(buttonsFuncs.frameOnKeyDown)(self, key);
		if (mouseoverButton:IsMouseOver()) then
			buttonSetTooltip(mouseoverButton);
		else
			GameTooltip:Hide();
		end
	end
end

--------------------------------------------
-- Options

local function keyBindingUpdate(option, value)
	wipeBindingCache();
end


---------------------------------------------
-- Converting from 9.0.5.7 to 9.0.5.8

module:regEvent("PLAYER_LOGIN", function()
	if (module:getOption("keyBindingsConvertedToButton31") ~= true) then
		module:setOption("keyBindingsConvertedToButton31", true)
		local needSave = false
		for i=1, 144 do
			local key1, key2 = GetBindingKey("CLICK CT_BarModActionButton" .. i .. ":LeftButton")
			if key1 then
				SetBinding(key1, "CLICK CT_BarModActionButton" .. i .. ":Button31")
				needSave = true
			end
			if key2 then
				SetBinding(key2, "CLICK CT_BarModActionButton" .. i .. ":Button31")
				needSave = true
			end
		end
		if (needSave) then
			SaveBindings(GetCurrentBindingSet())
			wipeBindingCache()
		end
	end
end)


--------------------------------------------
-- Public functions

module.keyBindingTemplate = keyBindingTemplate;
module.keyBindingOnLoad = keyBindingOnLoad;
module.keyBindingOnShow = keyBindingOnShow;
module.keyBindingOnKeyDown = keyBindingOnKeyDown;

module.setActionBindings = setActionBindings;

module.bindingUpdate = keyBindingUpdate;
module.clearKeyBindingsCache = wipeBindingCache;