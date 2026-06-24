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

-- Options
local displayBindings = true;
local displayRangeDot = true;
local displayActionText = true;
local displayCount = true;
local displayRecharge = true;
local colorLack = 1;
local buttonLock = false;
local buttonLockKey = 3;
local hideGrid = false;
local hideTooltip = false;
local actionBindings = true;
local bar3Bindings = true;
local bar4Bindings = true;
local bar5Bindings = true;
local bar6Bindings = true;
local hideGlow = false;
local useNonEmptyNormal = false;
local backdropShow = false;
local minimumCooldownToBling = 0;

local normalTexture1 = "Interface\\Buttons\\UI-Quickslot";  -- square texture that has a filled in center
local normalTexture2 = "Interface\\Buttons\\UI-Quickslot2"; -- square texture that has an empty center

local defbarShowRange = true;
local defbarShowCooldown = true;
local defbarShowRecharge = true;
local defbarShowBindings = true;
local defbarShowActionText = true;
local defbarSetUnitAttributes = true;
local defbarHideTooltip = true;

local unitAttribute1, unitAttribute2, unitAttribute3 = nil, nil, nil;	-- @mouseover, @self or @focus on the left, right or middle buttons.
local UNIT_ATTRIBUTES = {nil, "target", "player", "pet", FocusFrame and "focus" or nil}

local inCombat = false;

-- End Initialization
--------------------------------------------

--------------------------------------------
-- Local Copies

local ipairs = ipairs;
local max = max;
local pairs = pairs;
local tinsert = tinsert;
local tremove = tremove;
local unpack = unpack;
local ceil = ceil;
local next = next;
local ActionButton_GetPagedID = ActionButton_GetPagedID or ActionBarActionButtonMixin.GetPagedID;		-- Shadowlands 9.0 vs. 8.x and earlier
local ActionButton_UpdateUsable = ActionButton_UpdateUsable or ActionBarActionButtonMixin.UpdateUsable;		-- Shadowlands 9.0 vs. 8.x and earlier
local ActionHasRange = ActionHasRange;
local CanExitVehicle = CanExitVehicle;
local GetActionCharges = GetActionCharges;
local GetActionCooldown = GetActionCooldown;

-- GetActionCount, overridden for WoW Classic 1.13.3 (CTMod 8.2.5.8) using GetItemCount and some tooltip scanning
local OldGetActionCount, GetActionCount, GetItemCount, ReagentScannerTooltip = GetActionCount, GetActionCount, GetItemCount, CreateFrame("GameTooltip", "CT_BarMod_ReagentScanner", nil, "GameTooltipTemplate");
local reagentScannerCache = {};
if (module:getGameVersion() == 1) then
	ReagentScannerTooltip:SetOwner(UIParent, "ANCHOR_NONE");
	
	local function scanSpellTooltip(spell)
		ReagentScannerTooltip:ClearLines();
		ReagentScannerTooltip:SetSpellByID(spell);
		for i=1, ReagentScannerTooltip:NumLines() do
			local text = _G["CT_BarMod_ReagentScannerTextLeft" .. i]:GetText();
			if (text and string.find(text, SPELL_REAGENTS)) then	
				local reagent = string.gsub(text, SPELL_REAGENTS, "");		-- strip out the localized header
				reagent = string.gsub(reagent, "|cffff2020(.*)|r", "$1");	-- strip out the red colour when there is insufficent quantity of the reagent
				reagentScannerCache[spell] = reagent;	-- add to the cache!
				return reagent;
			end
		end		
	end	
	
	function GetActionCount(actionId)
		
		-- perform custom execution only if this item is likely to require a reagent
		if (IsConsumableAction(actionId) and not IsItemAction(actionId)) then
			
			local actionType, actionInfoId = GetActionInfo(actionId);
			
			if (actionType == "macro") then
				local spell = GetMacroSpell(actionInfoId);
				if (spell) then
					local item = reagentScannerCache[spell] or scanSpellTooltip(spell);
					return item and GetItemCount(item) or OldGetActionCount(actionId);
				end
			elseif (actionType == "spell") then
				local item = reagentScannerCache[actionInfoId] or scanSpellTooltip(actionInfoId);
				return item and GetItemCount(item) or OldGetActionCount(actionId);
			end
		end
		
		-- this item does not appear to require a reagent, so use the native API method
		return OldGetActionCount(actionId);
	end
end

local GetActionInfo = GetActionInfo;
local GetActionLossOfControlCooldown = GetActionLossOfControlCooldown;
local GetActionRange = GetActionRange;
local GetActionText = GetActionText;
local GetActionTexture = GetActionTexture;
local GetBindingAction = GetBindingAction;
local GetBindingKey = GetBindingKey;
local GetMacroSpell = GetMacroSpell;
local GetPossessInfo = GetPossessInfo;
local GetTime = GetTime;
local HasAction = HasAction;
local IsActionInRange = IsActionInRange;
local IsAttackAction = IsAttackAction;
local IsAutoRepeatAction = IsAutoRepeatAction;
local IsConsumableAction = IsConsumableAction;
local IsCurrentAction = IsCurrentAction;
local IsEquippedAction = IsEquippedAction;
local IsItemAction = IsItemAction;
-- IsSpellOverlayed was removed in modern clients (moved to C_SpellActivationOverlay); use the shared
-- CT_Library helper, which returns false when no overlay API exists so proc-glow never nil-crashes.
local IsSpellOverlayed = CT_Library.isSpellOverlayed;
local IsStackableAction = IsStackableAction;
local IsUsableAction = IsUsableAction;
local rangeIndicator = RANGE_INDICATOR;
local UnitExists = UnitExists;

-- In Midnight, action data (cooldown start/duration, action count, charges) is a restricted "secret"
-- value when read by tainted addon code in combat; comparing/using it crashes. ctSafe returns the value
-- when it is a normal comparable number, else the default -- so the button update degrades gracefully
-- (cooldown/count simply not shown in combat) instead of erroring/spamming. NOTE: full in-combat display
-- is not achievable from insecure code; it would require driving updates via Blizzard's secure system.
local ctSafe = CT_Library.safeValue;	-- shared secret-value sanitizer (see CT_Library.lua)

-- End Local Copies
--------------------------------------------

--------------------------------------------
-- Cooldown Handler

local cooldownList = {};
local cooldownUpdater;

local function updateCooldown(fsCount, time)
	if ( time > 3540 ) then
		-- Hours
		fsCount:SetText(ceil(time/3600).."h");
	elseif ( time > 60 ) then
		-- Minutes
		fsCount:SetText(ceil(time/60).."m");
	elseif ( time > 1 ) then
		-- Seconds
		fsCount:SetText(ceil(time));
	else
		fsCount:SetText("");
	end
end

local function dropCooldownFromQueue(button)
	cooldownList[button] = nil;
	if ( not next(cooldownList) ) then
		module:unschedule(cooldownUpdater, true);
	end
end

cooldownUpdater = function()
	local currTime = GetTime();
	local start, duration, enable;
	for button, fsCount in pairs(cooldownList) do
		if button.actionId then
			start, duration, enable = GetActionCooldown(button.actionId);
			start, duration = ctSafe(start, 0), ctSafe(duration, 0);	-- secret in combat -> 0 (cooldown not shown)
			if ( start > 0 and (enable and enable ~= 0) ) then	-- enable is a boolean in Midnight (was 1/0)
				updateCooldown(fsCount, duration - (currTime - start));
			else
				dropCooldownFromQueue(button);
			end
		end
	end
end

local function stopCooldown(cooldown)
	local fsCount = cooldown.fsCount;
	if ( fsCount ) then
		fsCount:Hide();
	end
	if (cooldown.object) then
		dropCooldownFromQueue(cooldown.object);
	end
end

local function hideCooldown(cooldown)
	local fsCount = cooldown.fsCount;
	if ( fsCount ) then
		fsCount:Hide();
	end
end

function CT_BarMod_HideShowAllCooldowns(show)
	for button, fsCount in pairs(cooldownList) do
		if ( fsCount ) then
			if (show) then
				fsCount:Show();
			else
				fsCount:Hide();
			end
		end
	end
end

local function startCooldown(cooldown, start, duration)
	if ( duration < 2 ) then
		stopCooldown(cooldown);
		return;
	end
	
	local fsCount = cooldown.fsCount;
	local font = "CT_BarMod_CooldownFont";
	if ( not fsCount ) then
		fsCount = cooldown:CreateFontString(nil, "OVERLAY", font);
		fsCount:SetPoint("CENTER", cooldown);
		cooldown.fsCount = fsCount;
	end
	
	if ( not next(cooldownList) ) then
		module:schedule(0.5, true, cooldownUpdater);
	end
	cooldownList[cooldown.object] = fsCount;
	
	fsCount:Show();
	updateCooldown(fsCount, duration - (GetTime() - start));
end

--------------------------------------------
-- Methods assigned to Use Button Class buttons that are called from secure snippets.

local function button_OnDragStart(self, button, actionId, kind, value, ...)
	self.object:ondragstart(button, actionId, kind, value, ...);
end

local function button_OnReceiveDrag(self, actionId, kind, value, ...)
	self.object:onreceivedrag(actionId, kind, value, ...);
end

--------------------------------------------
-- Use Button Class

local useButton = { };
local actionButton = module.actionButtonClass;
local actionButtonList = module.actionButtonList;

setmetatable(useButton, { __index = actionButton });
module.useButtonClass = useButton;

-- Constructor
function useButton:constructor(buttonId, actionId, groupId, count, ...)
	actionButton.constructor(self, buttonId, actionId, groupId, count, ...);
	
	-- Do stuff
	local button = self.button;
	-- Notes regarding the last two buttons of the pages beyond 10.
	-- Originally this was just action id 131 and action id 132 on page 11.
	-- Now in WoW 5, there is more than one page beyond 10.
	-- 
	-- Since these action ids aren't used for anything, we're
	-- going to use them to display a button that can be used
	-- to cancel control, and one that can be used to leave a vehicle.
	--
	-- There are a few other places in this addon that tests
	-- for these action id numbers.

	-- As of 4.0200 this was just a single button that clicked Blizzard's
	-- PossessButton2. Blizzard's code for that button would either cancel control
	-- or leave a vehicle (see PossessButton_OnClick() in PossessActionBar.lua).
	--
	-- As of 4.0201 we are now using separate cancel and leave buttons.
	--
	-- Problem 1: Sometimes when you are in an exitable vehicle Blizzard does not
	-- setup PossessButton2, so clicking it has no effect and you do not leave
	-- the vehicle as expected.
	--
	-- Problem 2: The game sometimes shows the bonus action bar (note: bonus action bar was
	-- removed in WoW 5.0) when there is no info available from GetPossessInfo(). Blizzard's
	-- click handler for the button does not verify if possess information is
	-- available before they try to cancel the buff. This can lead to an error
	-- when Blizzard tries to cancel a nil buff.

	-- There are two ways we could configure this button...
	--
	-- 1) Set the "type" attribute to nil, and then handle the click
	-- in the PreClick, OnClick, or PostClick scripts.
	-- The VehicleExit() function is one that can be called from unsecure
	-- code during combat.
	--
	-- 2) To make the button click the PossessButton2 we need to set the
	-- "type" attribute to "click", and assign PossessButton2 to the
	-- "clickbutton" attribute. The assigment of the button to "clickbutton"
	-- must be done from unsecure code. Since we have two bars that this
	-- button could appear on, it needs to be assigned to both of them.
	--
	-- We can't use a secure frame reference to a button like PossessButton2
	-- since the frame reference does not have a "Click" method that the
	-- SecureTemplates.lua routine wants to use when our action button
	-- gets clicked.

	-- We're going to initialize all "type" attributes to "action" for now
	-- and configure the special button properly when the state driver detects
	-- a page change.
	button:SetAttribute("type", "action");

	-- Set the "clickbutton" attribute of the 11th button on each bar to be the PossessButton that cancels possession or exits vehicles.
	-- Set the "clickbutton" attribute of the 12th button on each bar to be the MainMenuBarVehicleLeaveButton.
	-- This attribute won't get used unless the "type" attribute for a button gets set to "click".
	-- We have to do it in unsecure code, since secure frame references don't support a "button:Click" method.
	if (count == 11) then
		button:SetAttribute("clickbutton", _G["PossessButton" .. (POSSESS_CANCEL_SLOT or 2)]);
	elseif (count == 12) then
		button:SetAttribute("clickbutton", MainMenuBarVehicleLeaveButton);
	else
		button:SetAttribute("clickbutton", nil);
	end

	button:SetAttribute("action", self.actionId);
	button:SetAttribute("checkselfcast", true);
	button:SetAttribute("checkfocuscast", true);
	button.border:SetVertexColor(0, 1, 0, 0.35);

	button:SetAttribute("actionMode", "action");  -- A CT_BarMod attribute. init to "action" for now.

	--  Methods used by secure snippets.
	button.ondragstart = button_OnDragStart;
	button.onreceivedrag = button_OnReceiveDrag;

	-- Assign to the button a reference to the secure frame so we can access the frame from the button's secure code.
	SecureHandlerSetFrameRef(button, "SecureFrame", CT_BarMod_SecureFrame);

	-- Assign to the button a reference to the SpellFlyout frame so we can hide it from the button's secure code.
	if (SpellFlyout) then
		SecureHandlerSetFrameRef(button, "SpellFlyout", SpellFlyout);
	end

	SecureHandlerWrapScript(button, "OnDragStart", button,
		[=[
			-- OnDragStart(self, button, kind, value, ...)
			-- self == the action button
			-- button == which mouse button was used (eg. "LeftButton")
			-- kind == nil
			-- value == nil
			-- ... == nil
			--
			-- The OnDragStart is called when you press the mouse button down over an action
			-- button and then move the mouse a certain distance while continuing to hold the
			-- mouse button down. This happens even if we return nil from this snippet,
			-- rather than picking up the action from the action button. If we don't pick up
			-- something now, the cursor will have a nil cargo on it that can be dropped
			-- on another button when the user releases the mouse button.

			-- If we have an action id...
			local actionId = self:GetAttribute("action");
			if (actionId) then
				-- Only pickup the action if buttonLock option is disabled or
				-- the modifier key is pressed.
				local secureFrame = self:GetFrameRef("SecureFrame");
				local buttonLock = secureFrame:GetAttribute("buttonlock");
				local buttonLockKey = secureFrame:GetAttribute("buttonlockKey") or 3;

				if (
					(not buttonLock) or
					(buttonLockKey == 1 and IsAltKeyDown()) or
					(buttonLockKey == 2 and IsControlKeyDown()) or
					(buttonLockKey == 3 and IsShiftKeyDown())
				) then
					-- Hide the spell flyout frame
					local flyout = self:GetFrameRef("SpellFlyout");
					if (flyout) then
						flyout:Hide();
					end

					-- Update the button before the action gets picked up.
					self:CallMethod("ondragstart", button, actionId, kind, value, ...);

					-- Pickup the action (using PickupAction(actionId))
					-- Return:
					-- 1) "clear" to clear the cursor contents.
					-- 2) "action" to pick up an action.
					-- 3) the action id to be picked up.
					return "clear", "action", actionId;
				end
			end
			-- Return:
			-- 1) false to prevent normal handler from being called.
			return false;
		]=]
	);

	SecureHandlerWrapScript(button, "OnReceiveDrag", button,
		[=[
			-- OnReceiveDrag(self, button, kind, value, ...)
			-- self == the action button
			-- button == nil
			-- kind == the type of item being dragged (eg. "spell", "macro")
			-- value == information about the item (eg. index number into player's spellbook)
			-- ... == information about the item (eg. "spell", "")
			--
			-- Our OnDragStart handler requires a modifier key to pick up an action if the button
			-- is locked. A drag start event occurs even if the user does not use the modifier key,
			-- however by doing so they will have a 'nil' cargo. This nil cargo can still be
			-- dropped on another button. For the other button to avoid swapping its action with the
			-- nil cargo, the OnReceiveDrag of the other button must not allow an action to be placed
			-- if the 'kind' parameter is nil.

			-- If we have an action id and some kind of thing is being dragged...
			local actionId = self:GetAttribute("action");
			if (actionId and kind) then
				-- Hide the spell flyout frame
				local flyout = self:GetFrameRef("SpellFlyout");
				if (flyout) then
					flyout:Hide();
				end

				-- Update the button before the action gets placed.
				self:CallMethod("onreceivedrag", actionId, kind, value, ...);

				-- Set a flag that we can test for in our secure code that handles the
				-- ACTIONBUTTON_HIDEGRID event. We want to be able to check if we just
				-- dragged an ability into this slot.
				--
				-- When our secure code for the event gets executed, HasAction() returns
				-- nil even though we are in the process of dropping an ability on the
				-- button. We'll use this flag to tell us that there should be an ability
				-- in this button so that we can properly update the visibilty of the button.
				--
				-- We can't update the visibility here, because this snippet gets executed
				-- before our secure event handling code does.
				--
				-- See actionButton_OnAttributeChanged_Pre_Secure in CT_BarMod_Groups.lua
				-- for the secure event handling code which uses a wrap around an action
				-- buttons OnAttributeChanged to detect Blizzard's setting of the "showgrid"
				-- attribute.

				local secureFrame = self:GetFrameRef("SecureFrame");
				local actionMode = self:GetAttribute("actionMode");
--				if (actionMode == "override" or actionMode == "vehicle" or actionMode == "possess" or actionMode == "cancel" or actionMode == "leave") then
				if (actionMode ~= "action") then
					-- These action id numbers don't accept items dropped onto the button.
					self:SetAttribute("receiveddrag", nil);
				else
					self:SetAttribute("receiveddrag", true);
				end

				-- Place the current action (using PickupAction(actionId)).
				-- We may end up with another action on the cursor after this action is placed.
				return "action", actionId;
			end
			-- Return:
			-- 1) false to prevent normal handler from being called.
			return false;
		]=]
	);

	SecureHandlerWrapScript(button, "PostClick", button,
		[=[
			-- Parameters: self, button, down
			-- self - the action button that was clicked
			-- button - the mouse button that was pressed or released
			-- down - flag indicating if this was a press or release (if relevant)

			-- We need this routine to be able to update the visibility of a button
			-- while in combat when the user drops an ability onto the button via
			-- a click rather than via a ReceiveDrag.
			--
			-- HasAction() will return a proper value for an ability that was just
			-- placed into this button via a click.

			-- For similar visibility code see also:
			-- 1) actionButton_OnAttributeChanged_Pre_Secure in CT_BarMod_Groups.lua
			-- 2) useButton:updateVisibility() in CT_BarMod_Use.lua
			-- 3) SecureHandlerWrapScript(button, "PostClick", ... in CT_BarMod_Use.lua
			-- 4) secureFrame_OnAttributeChanged in CT_BarMod.lua

			local show;
			local button = self;

			-- If we are showing this button (ie. it is not being forced hidden)...
			if (button:GetAttribute("showbutton")) then

				-- If a show grid event is not currently active...
				if (button:GetAttribute("gridevent") == 0) then

					-- If the button has an action...
					local actionId = button:GetAttribute("action");
					local actionMode = button:GetAttribute("actionMode");
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

			-- Clear our receive drag flag, in case it was set by our OnReceiveDrag snippet.
			button:SetAttribute("receiveddrag", nil);

			return nil;  -- we want the wrapped handler to be called with the original button
		]=]
	);

end

-- Destructor
function useButton:destructor(...)
	-- Do stuff
	self.hasAction = nil;
	self.hasRange = nil;
	self.actionType = nil;
	self.checked = nil;
	
	if ( self.flashing ) then
		self:stopFlash();
	end
	
	actionButton.destructor(self, ...);
end

function useButton:getNormalTexture(name)
	-- Get the button's normal texture.
	local button = self.button;
	if (module:isMasqueLoaded()) then
		-- Get the normal texture from Masque.
		return module:getMasqueNormalTexture(button);
	else
		-- Get the normal texture from the button.
		return button:GetNormalTexture();
	end
end

function useButton:setNormalTexture(name)
	-- Set the button's normal texture.
	local button = self.button;
	if (module:isMasqueLoaded()) then
		module:setMasqueNormalTexture(button, name);
	else
		button:SetNormalTexture(name);
	end
end

function useButton:updateVisibility()
	if (inCombat) then
		return;
	end

	-- For similar visibility code see also:
	-- 1) actionButton_OnAttributeChanged_Pre_Secure in CT_BarMod_Groups.lua
	-- 2) useButton:updateVisibility() in CT_BarMod_Use.lua
	-- 3) SecureHandlerWrapScript(button, "PostClick", ... in CT_BarMod_Use.lua
	-- 4) secureFrame_OnAttributeChanged in CT_BarMod.lua

	local show;
	local button = self.button;

	-- If we are showing this button (ie. it is not being forced hidden)...
	if (button:GetAttribute("showbutton")) then

		-- If a show grid event is not currently active...
		if (button:GetAttribute("gridevent") == 0) then

			-- If the button has an action...
			local actionMode = button:GetAttribute("actionMode");
			if (self.hasAction) then
				show = true;
			elseif (self.actionMode == "cancel" ) then
				show = true;
			elseif (self.actionMode == "leave" ) then
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

local needSetUnitTargetingAttributes;
function useButton:updateUnitAttributes()
	if (InCombatLockdown()) then
		needSetUnitTargetingAttributes = true;
	else
		self.button:SetAttribute("unit1", unitAttribute1);
		self.button:SetAttribute("unit2", unitAttribute2);
		self.button:SetAttribute("unit3", unitAttribute3);
	end
end

-- Update everything
function useButton:update()
	local actionId = self.actionId;
	local actionMode = self.actionMode;
	local button = self.button;

	-- ActionHasRange(actionId):
	-- - For action ids 121 to 132 it returns 1 or nil.
	--
	-- GetActionInfo(actionId):
	-- - For action ids 121 to 132:
	--	- it returns 3 values (eg. "spell", 82577, "spell") for slots with something in them.
	--	- it returns these 3 values ("spell", 0, "spell") for slots with nothing in them.
	--
	-- GetActionText(actionId):
	-- - For action ids 121 to 132 it returns nil for all slots.
	--
	-- GetActionTexture(actionId):
	-- - For action ids 121 to 132 it returns nil if there is nothing in the slot, else it returns the texture path.
	--
	-- HasAction(actionId):
	-- - For action ids 121 to 130 it returns   1 for all slots.
	-- - For action ids 131 to 132 it returns nil for all slots
	--
	-- IsEquippedAction(actionId):
	-- - For action ids 121 to 132 it returns nil for all slots.
	--
	-- IsUsableAction(actionId)
	-- - For action ids 121 to 132 it returns nil slots with nothing in them, 1 for slots with usable items, other?

	local hasAction = HasAction(actionId);

	self.hasAction = hasAction;
	self.hasRange = ActionHasRange(actionId);
	self.actionType = GetActionInfo(actionId);
	
	self.isConsumable = IsConsumableAction(actionId);
	self.isStackable = IsStackableAction(actionId);
	self.isItem = IsItemAction(actionId);
	
	
--	self:updateCount();
	self:updateBinding();
	self:updateRange();
	self:updateTexture();
--	self:updateState();  -- updateFlash() calls updateState().
	self:updateFlash();
	self:updateUnitAttributes();
	if ( hasAction or actionMode == "cancel" or actionMode == "leave" ) then
		self:updateUsable();
		self:updateCooldown();
		self:updateLock();
		self:updateVisibility();
	else
		button.cooldown:Hide();
		button.recharge:Hide();
		self:updateVisibility();
	end
	
	-- Textures
	if ( hasAction ) then
		local icon = button.icon;
		local texture = GetActionTexture(actionId);
		if (texture) then
			icon:SetTexture(texture);
			self:setNormalTexture(normalTexture2);
			self:updateCount();
		else
			icon:SetTexture(nil);
			if (useNonEmptyNormal) then
				self:setNormalTexture(normalTexture2);
			else
				self:setNormalTexture(normalTexture1);
			end
			self.button.count:SetText("");
		end
		icon:Show();

	elseif (actionMode == "cancel") then
		-- Icon used for cancel possession button
		--local texture, name, enabled = GetPossessInfo(POSSESS_CANCEL_SLOT or 2);  -- may not always have a value
		button.icon:SetTexture("Interface\\Icons\\Spell_Shadow_SacrificialShield");
		button.icon:Show();
		self:setNormalTexture(normalTexture2);
		self.button.count:SetText("");

	elseif (actionMode == "leave") then
		-- Icon used for vehicle exit button
		button.icon:SetTexture("Interface\\AddOns\\CT_BarMod\\Images\\icon_vehicle_leave");
		button.icon:Show();
		self:setNormalTexture(normalTexture2);
		self.button.count:SetText("");

	else
		button.icon:Hide();
		if (useNonEmptyNormal) then
			self:setNormalTexture(normalTexture2);
		else
			self:setNormalTexture(normalTexture1);
		end
		self.button.count:SetText("");
	end
	
	-- Equip
	if ( IsEquippedAction(actionId) ) then
		button.border:SetVertexColor(0, 1.0, 0, 0.35); -- green border for equipped items
		button.border:Show();
	else
		button.border:Hide();
	end
	
	-- Action text
	if ( displayActionText and not self.isConsumable and not self.isStackable and (self.isItem or ctSafe(GetActionCount(actionId), 0) == 0) ) then
		button.name:SetText(GetActionText(actionId));
	else
		button.name:SetText("");
	end

	-- Flyout appearance (This was added to the default ui in WoW patch 4.0.1)
	self:updateFlyout();

	-- Overlay glow (This was added to the default ui in WoW patch 4.0.1)
	self:updateOverlayGlow();
end

-- Jan 2, 2012
--
-- The following overlay glow routines are modifed version of the ones in Blizzard's FrameXML\ActionButton.lua.
-- I've changed their names and rearranged their order so that they can be "local" functions.
--
-- We can't use Blizzard's functions directly any more because doing so introduces some taint which produces
-- the following error (from the taint.log file):
--
-- 1/2 16:31:34.374  An action was blocked in combat because of taint from CT_BarMod - ActionButton10:Show()
-- 1/2 16:31:34.374      Interface\FrameXML\ActionButton.lua:246
-- 1/2 16:31:34.374      ActionButton_Update()
-- 1/2 16:31:34.374      Interface\FrameXML\ActionButton.lua:484 ActionButton_OnEvent()
-- 1/2 16:31:34.374      Interface\FrameXML\ActionButton.lua:105
-- 1/2 16:31:34.374      UseAction()
-- 1/2 16:31:34.374      Interface\FrameXML\SecureTemplates.lua:275 handler()
-- 1/2 16:31:34.374      Interface\FrameXML\SecureTemplates.lua:561
--
-- Line 246 in ActionButton.lua was attempting to Show() the button. We don't have access to the 
-- Show() programming, but it appears that something in that routine was trying to access a tainted
-- value.
--
-- By creating a copy of the overlay glow related routines from ActionButton.lua, adjusting the overlay
-- frame template that is used, and using our own local table to recycle frames, we can avoid tainting
-- Blizzard's code.
--
-- Some observations:
--
-- - When I was testing, I was using a shadowpriest who had mind blast on the 9th button of the main action bar.
--   This is why the action blocked errors I was getting only started with the 10th ActionButton.
--
-- - I was getting the error when doing the following: Reload UI, enter combat with no shadow orbs, gain 3 shadow
--   orbs (this triggers some button overlay code), press the button that Shadowform is assigned to.
--
-- - The "feedback_action" key in the ActionButton10 table indicated that it had been tainted by CT_BarMod.
--   The same key in ActionButton9 was not tainted.
--   /run for k, v in pairs(ActionButton10) do print(k, issecurevariable(ActionButton10, k)) end
--
-- - Using Blizzard's functions directly causes "tainted" overlay frames created by CT_BarMod to get
--   added to a local table called "unusedOverlayGlows" that Blizzard maintains to recycle frames.
--   If Blizzard re-uses an old CT_BarMod overlay frame, then taint could be introduced.
--

--Overlay stuff
local unusedOverlayGlows = {};
local numOverlays = 0;

local function CT_BarMod__ActionButton_OverlayGlowAnimOutFinished(overlay)
	-- This is a modified version of ActionButton_OverlayGlowAnimOutFinished from ActionButton.lua
	local actionButton = overlay:GetParent();
	overlay:Hide();
	tinsert(unusedOverlayGlows, overlay);
	actionButton.overlay = nil;
end

local function CT_BarMod__ActionButton_GetOverlayGlow()
	-- This is a modified version of ActionButton_GetOverlayGlow from ActionButton.lua
	local overlay = tremove(unusedOverlayGlows);
	if ( not overlay ) then
		-- The "ActionBarButtonSpellActivationAlert" template was removed in Midnight; pcall so a missing
		-- template doesn't error -- the proc glow just won't show rather than crashing the button update.
		local ok, frame = pcall(CreateFrame, "Frame", "CT_BarMod__ActionButtonOverlay" .. (numOverlays + 1), UIParent, "ActionBarButtonSpellActivationAlert");
		if (ok and frame) then
			numOverlays = numOverlays + 1;
			overlay = frame;
		end
	end
	return overlay;	-- may be nil if the template no longer exists
end

local function CT_BarMod__ActionButton_HideOverlayGlow(self)
	-- This is a modified version of ActionButton_HideOverlayGlow from ActionButton.lua
	if self.overlay then
		if (self.overlay.ProcStartAnim or self.overlay.animIn):IsPlaying() then  -- Retail vs Cata Classic
			(self.overlay.ProcStartAnim or self.overlay.animIn):Stop();
		end
		if ( self:IsVisible() ) then
			self.overlay:Hide()
		else
			CT_BarMod__ActionButton_OverlayGlowAnimOutFinished(self.overlay);
		end
	end
end

local function CT_BarMod__ActionButton_ShowOverlayGlow(self)
	-- This is a modified version of ActionButton_ShowOverlayGlow from ActionButton.lua
	if (hideGlow) then
		CT_BarMod__ActionButton_HideOverlayGlow(self);
		return;
	end
	if self.overlay then
		if self.overlay:IsShown() then
			if self.overlay.animOut and self.overlay.animOut:IsPlaying() then
				self.overlay.animOut:Stop()
			end
		else
			self.overlay:Show()
		end
		(self.overlay.ProcStartAnim or self.overlay.animIn):Play()
	else
		self.overlay = CT_BarMod__ActionButton_GetOverlayGlow();
		if (not self.overlay) then return; end	-- glow template unavailable in Midnight; skip silently

		if (module:usingMasque()) then
			-- Have Masque assign spell alert textures based on the shape of the skin.
			module:skinMasqueSpellAlert(self);
		else
			-- Assign spell alert textures for CT_BarMod.
			-- The CT_BarMod skins are square only, so pass nil for the
			-- Glow and Ants textures to use the default square textures.
			module:skinOverlayGlow(self, nil, nil);
		end

		local frameWidth, frameHeight = self:GetSize();
		self.overlay:SetParent(self);
		self.overlay:ClearAllPoints();
		self.overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4);
		self.overlay:SetPoint("TOPLEFT", self, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2);
		self.overlay:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2);
		(self.overlay.ProcStartAnim or self.overlay.animIn):Play();
	end
end

local function CT_BarMod__ActionButton_UpdateOverlayGlow(self)
	-- This is a modified version of ActionButton_UpdateOverlayGlow from ActionButton.lua
	local spellType, id, subType  = GetActionInfo(self.action);
	if ( spellType == "spell" and IsSpellOverlayed(id) ) then
		CT_BarMod__ActionButton_ShowOverlayGlow(self);
	elseif ( spellType == "macro" ) then
		local spellId = GetMacroSpell(id);
		if ( spellId and IsSpellOverlayed(spellId) ) then
			CT_BarMod__ActionButton_ShowOverlayGlow(self);
		else
			CT_BarMod__ActionButton_HideOverlayGlow(self);
		end
	else
		CT_BarMod__ActionButton_HideOverlayGlow(self);
	end
end

function useButton:updateOverlayGlow()
	if (module:getGameVersion() >= 4) then
		CT_BarMod__ActionButton_UpdateOverlayGlow(self.button);
	end
end

function useButton:showOverlayGlow(arg1)
	-- Based on the code that handles the "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" event in ActionButton.lua
	local actionType, id, subType = GetActionInfo(self.actionId);
	if ( actionType == "spell" and id == arg1 ) then
		CT_BarMod__ActionButton_ShowOverlayGlow(self.button);
	elseif ( actionType == "macro" ) then
		-- id == macro number
		local spellId = GetMacroSpell(id);
		if (spellId and spellId == arg1 ) then
			CT_BarMod__ActionButton_ShowOverlayGlow(self.button);
		end
	elseif (actionType == "flyout" and FlyoutHasSpell(id, arg1)) then
		CT_BarMod__ActionButton_ShowOverlayGlow(self.button);
	end
end

function useButton:hideOverlayGlow(arg1)
	-- Based on the code that handles the "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" event in ActionButton.lua
	local actionType, id, subType = GetActionInfo(self.actionId);
	if ( actionType == "spell" and id == arg1 ) then
		-- id == spell number
		CT_BarMod__ActionButton_HideOverlayGlow(self.button);
	elseif ( actionType == "macro" ) then
		-- id == macro number
		local spellId = GetMacroSpell(id);
		if (spellId and spellId == arg1 ) then
			CT_BarMod__ActionButton_HideOverlayGlow(self.button);
		end
	elseif (actionType == "flyout" and FlyoutHasSpell(id, arg1)) then
		CT_BarMod__ActionButton_HideOverlayGlow(self.button);
	end
end

if ActionButton_UpdateFlyout then
	-- prior to WoW 10.x
	function useButton:updateFlyout()
		-- Call Blizzard's function to update the flyout bar.
		ActionButton_UpdateFlyout(self.button)
	end
else
	-- WoW 10.x
	function useButton:updateFlyout()
		if InCombatLockdown() then
			module:afterCombat(useButton.updateFlyout, self)	-- to do this inside combat, it would be necessary to trigger the restricted environment whenever GetActionInfo() changes, and also having flyout info available beforehand
			return
		end
		module.updateFlyout(self.button)	-- congfigures the arrow textures
		local type, id = GetActionInfo(self.button.action)
		if type == "flyout" then
			local numSlots = select(3,GetFlyoutInfo(id))
			local numKnownSlots = 0
			for i=1, numSlots do
				local spellID, overrideSpellID, isKnown = GetFlyoutSlotInfo(id, i)
				if isKnown then
					numKnownSlots = numKnownSlots + 1
					self.button:SetAttribute("spell"..numKnownSlots, spellID)
				end
			end
			self.button:SetAttribute("numKnownSlots", numKnownSlots)
			module.createSpellFlyoutButtons(numKnownSlots)
		else
			self.button:SetAttribute("numKnownSlots", 0)
		end
	end
end

-- Check button lock state to disable shift-click
function useButton:updateLock()
	--[[ Disabling this functionality for now
	if ( buttonLock ) then
		self.button:SetAttribute("shift-type*", ATTRIBUTE_NOOP);
	else
		self.button:SetAttribute("shift-type*", nil);
	end
	--]]
end

-- Update Usable
function useButton:updateUsable()
	local isUsable, notEnoughMana = IsUsableAction(self.actionId);
	local button = self.button;
	
	if ( self.actionMode == "cancel" ) then
		local texture, name, enabled = GetPossessInfo(POSSESS_CANCEL_SLOT or 2);
		if (enabled) then
			button.icon:SetVertexColor(1, 1, 1);
			button.blingcontainer:Show();
		else
			button.icon:SetVertexColor(0.4, 0.4, 0.4);
			button.blingcontainer:Hide();
		end

	elseif ( self.actionMode == "leave" ) then
		if (CanExitVehicle()) then
			button.icon:SetVertexColor(1, 1, 1);
			button.blingcontainer:Show();
		else
			button.icon:SetVertexColor(0.4, 0.4, 0.4);
			button.blingcontainer:Hide();
		end

	elseif ( colorLack and self.outOfRange ) then
		if ( colorLack == 2 ) then
			button.icon:SetVertexColor(0.5, 0.5, 0.5);
			button.blingcontainer:Show();
		else
			button.icon:SetVertexColor(0.8, 0.4, 0.4);
			button.blingcontainer:Show();
		end
		
	elseif (
		isUsable
		and (
			module:getGameVersion() > 1
			or not self.isConsumable	-- reagents behave differently in classic
			or self.isItem
			or GetActionCount(self.actionId) > 0
		)
	) then
		button.icon:SetVertexColor(1, 1, 1);
		button.blingcontainer:Show();
		
	elseif ( notEnoughMana ) then
		button.icon:SetVertexColor(0.5, 0.5, 1);
		button.blingcontainer:Hide();

	elseif ( self.actionType == "companion" and not InCombatLockdown()) then
		button.icon:SetVertexColor(1, 1, 1);
		button.blingcontainer:Show();
	
	else
		button.icon:SetVertexColor(0.4, 0.4, 0.4);
		button.blingcontainer:Hide();
	end
end

-- Update Cooldown
function useButton:updateCooldown()
	if (self.hasAction) then
	
		local actionCooldown, controlCooldown;
		local cooldown = self.button.cooldown;
		local bling = self.button.bling;
		local recharge = self.button.recharge;
		
		-- Action cooldown
		local start, duration, enable = GetActionCooldown(self.actionId);
		start, duration = ctSafe(start, 0), ctSafe(duration, 0);	-- secret in combat -> 0 (cooldown not shown)
		if ( start > 0 and (enable and enable ~= 0) ) then	-- enable is a boolean in Midnight (was 1/0)
			cooldown:SetCooldown(start, duration);
			actionCooldown = true;
			if ( displayCount ) then
				startCooldown(cooldown, start, duration);
			else
				stopCooldown(cooldown);
			end
			bling:SetShown(duration >= minimumCooldownToBling)
		else
			stopCooldown(cooldown);
			actionCooldown = false;
		end

		-- Loss of control cooldown
		local start, duration = GetActionLossOfControlCooldown(self.actionId);
		start, duration = ctSafe(start, 0), ctSafe(duration, 0);	-- secret in combat -> 0
		--cooldown:SetLossOfControlCooldown(start, duration);
		if (start > 0 and duration > 0) then
			controlCooldown = true;
			bling:SetShown(duration >= minimumCooldownToBling)
		else
			controlCooldown = false;
		end

		-- Hide/show the cooldown
		if (actionCooldown or controlCooldown) then
			cooldown:Show();
		else
			cooldown:Hide();
		end

		-- Recharge animation
		local current, maxCharges, start, duration, modRate = GetActionCharges(self.actionId);
		current, maxCharges, start, duration = ctSafe(current, 0), ctSafe(maxCharges, 0), ctSafe(start, 0), ctSafe(duration, 0);	-- secret in combat -> 0
		if (displayRecharge and current > 0 and current < maxCharges) then
			recharge:SetCooldown(start, duration, modRate);
			recharge:Show();
		else
			recharge:Hide();
		end
	
	end
end

-- Update State
function useButton:updateState(checked)
	local actionId = self.actionId;
	if (checked == nil) then
		checked = IsCurrentAction(actionId) or IsAutoRepeatAction(actionId);
	end
	if ( checked ) then
		self.checked = true;
		self.button:SetChecked(true);
		self.button.checkedTexture:Show();
	else
		self.checked = nil;
		self.button:SetChecked(false);
		self.button.checkedTexture:Hide();
	end
end

-- Update Binding
function useButton:updateBinding()
	local hotkey = self.button.hotkey
	if (self.hasAction) then
		local text;
		if ( displayBindings ) then		
			text = self:getBinding();
		end
		if (text) then
			hotkey:SetText(text);
			hotkey.showRangeIndicator = nil;
		elseif (self.hasRange and IsActionInRange(self.actionId) ~= nil and displayRangeDot) then
			-- this ability has a range limitation applicable to the current target
			hotkey:SetText(rangeIndicator);
		else
			hotkey:SetText("");
		end
	else
		hotkey:SetText("");
	end
end

-- Update Range
function useButton:updateRange()
	if (self.hasAction) then
		local hotkey = self.button.hotkey;
		if (self.hasRange) then
			if (IsActionInRange(self.actionId) ~= false) then
				self.outOfRange = nil;
				hotkey:SetVertexColor(0.6, 0.6, 0.6);
			else
				self.outOfRange = true
				hotkey:SetVertexColor(1.0, 0.1, 0.1);
			end
		else
			self.outOfRange = nil;
			hotkey:SetVertexColor(0.6, 0.6, 0.6);
		end
	end
	
	if ( colorLack ) then
		self:updateUsable();
	end
end

-- Clears previous range indications (called once when the player no longer has a target)
function useButton:clearRange()
	if (self.hasAction and self.hasRange) then
		self.outOfRange = nil;
		self.button.hotkey:SetVertexColor(0.6, 0.6, 0.6);
	end
end

-- Update Count
function useButton:updateCount()
	local actionId = self.actionId;
	local text = self.button.count;
	if ( self.hasAction ) then
		local count = GetActionCount(actionId)
		count = ctSafe(count, 0);	-- secret in combat -> 0 (count not shown)
		if (
			self.isConsumable
			or self.isStackable
			or (not self.isItem and count > 0)
		) then
			text:SetText(count < 1000 and count or "*");
		else
			local charges, maxCharges, chargeStart, chargeDuration = GetActionCharges(actionId);
			charges, maxCharges = ctSafe(charges, 0), ctSafe(maxCharges, 0);	-- secret in combat -> 0
			chargeStart, chargeDuration = ctSafe(chargeStart, 0), ctSafe(chargeDuration, 0);
			if (maxCharges > 1) then
				text:SetText(charges);
			else
				text:SetText("");
			end
		end
	else
		text:SetText("");
	end
end

-- Update Flash
function useButton:updateFlash(flash)
	local actionId = self.actionId;
	if (flash == nil) then
		flash = ( IsAttackAction(actionId) and IsCurrentAction(actionId) ) or IsAutoRepeatAction(actionId);
	end
	if ( flash ) then
		self:startFlash();
	elseif ( self.flashing ) then
		self:stopFlash();
	end
	self:updateState();
end

function useButton:updateBackdrop()
	if (backdropShow) then
		self.button.backdrop:Show();
	else
		self.button.backdrop:Hide();
	end
end

-- Show Grid
function useButton:showGrid()
	-- Set flag to indicate that this button should be shown if it is empty.
	self.gridShow = self.gridShow + 1;
	if (not inCombat) then
		self.button:SetAttribute("gridshow", self.gridShow);
	else
		module.needSetAttributes = true;
	end
--	self.button.normalTexture:SetVertexColor(1, 1, 1, 0.5);
--	self:getNormalTexture():SetVertexColor(1, 1, 1, 0.5);
end

-- Hide Grid
function useButton:hideGrid()
	-- Set flag to indicate that this button should be hidden if it is empty.
	self.gridShow = max(0, self.gridShow - 1);
	self:updateUsable();
	if (not inCombat) then
		self.button:SetAttribute("gridshow", self.gridShow);
	else
		module.needSetAttributes = true;
	end
end


-- cache to improve the performance of useButton:getBinding()
local hasCachedBindingKeys, cachedBindingKey1, cachedBindingKey2 = {}, {}, {}
local function getActionBindingKey(value)
	-- Returns key(s) currently bound to the default game button number.
	-- Eg. "1", "SHIFT-A", etc.
	
	if (hasCachedBindingKeys[value]) then
		return cachedBindingKey1[value], cachedBindingKey2[value]
	else
		local key1, key2 = GetBindingKey(value);
		hasCachedBindingKeys[value], cachedBindingKey1[value], cachedBindingKey2[value] = true, key1, key2
		return key1, key2
	end
end

-- another cache to improve the performance of useButton:getBinding()
local checkedBindingActions = {}
local checkBindingAction = function(key, buttonId, actionExpected)
	-- Confirms that the binding really does point to CT_BarMod and hasn't been overriden to something else
	if (checkedBindingActions[key] == nil) then
		checkedBindingActions[key] = (actionExpected == GetBindingAction(key, true))
	end
	return checkedBindingActions[key]
end

local function wipeBindingCaches()
	wipe(hasCachedBindingKeys)
	wipe(checkedBindingActions)
end

hooksecurefunc("SetOverrideBinding", wipeBindingCaches);
hooksecurefunc("SetOverrideBindingSpell", wipeBindingCaches);
hooksecurefunc("SetOverrideBindingItem", wipeBindingCaches);
hooksecurefunc("SetOverrideBindingMacro", wipeBindingCaches);
hooksecurefunc("SetOverrideBindingClick", wipeBindingCaches);
hooksecurefunc("ClearOverrideBindings", wipeBindingCaches);

-- Get Binding
local cachedBindingText = {}	-- used near the end of useButton:getBinding() to improve performance
local frame2, frame3, frame4, frame5, frame12;
local func2, func3, func4, func5, func12;
function useButton:getBinding()
	-- local text = module:getOption("BINDING-"..self.buttonId);
	local text;
	local id = self.buttonId
	local showBar, showDef;
	local groupId = self.groupId;
	if (not frame2) then
		frame2 = module:getGroup(2).frame
		frame3 = module:getGroup(3).frame
		frame4 = module:getGroup(4).frame
		frame5 = module:getGroup(5).frame
		frame12 = module:getGroup(12).frame
		func2 = frame2.IsShown
		func3 = frame3.IsShown
		func4 = frame4.IsShown
		func5 = frame5.IsShown
		func12 = frame12.IsShown
	end
	if (groupId == 12) then		-- if (groupId == module.actionBarId)		-- hardcoding the value 12 to improve performance
		-- showBar = module:getOption("showGroup" .. module.actionBarId) ~= false;
		showBar = func12(frame12);
		showDef = actionBindings;
	elseif (groupId == 2) then -- CT bar 3 (game Right Bar)
		--showBar = module:getOption("showGroup2") ~= false;
		showBar = func2(frame2);	
		showDef = bar3Bindings;
	elseif (groupId == 3) then -- CT bar 4 (game Right Bar 2)
		--showBar = module:getOption("showGroup3") ~= false;
		showBar = func3(frame3);	
		showDef = bar4Bindings;
	elseif (groupId == 4) then -- CT bar 5 (game Bottom Right Bar)
		--showBar = module:getOption("showGroup4") ~= false;
		showBar = func4(frame4);
		showDef = bar5Bindings;
	elseif (groupId == 5) then -- CT bar 6 (game Bottom Left Bar)
		--showBar = module:getOption("showGroup5") ~= false;
		showBar = func5(frame5);	
		showDef = bar6Bindings;
	end
	
	if (showBar and showDef and self.actionName) then
		-- Get the key used on the default action bar's corresponding button.
		local key1, key2 = getActionBindingKey(self.actionName .. self.buttonNum);
		if (key1 and checkBindingAction(key1, id, self.actionName .. self.buttonNum)) then
			text = key1;
		elseif (key2 and checkBindingAction(key2, id, self.actionName .. self.buttonNum)) then
			text = key2;
		end
	end
	
	if (not text) then
		-- Get the key assigned directly to this (our) button.
		local key1, key2 = module.getBindingKey(id);
		if (key1 and checkBindingAction(key1, id, (self.actionName and (self.actionName .. self.buttonNum)) or "CLICK CT_BarModActionButton" .. id .. ":Button31")) then			--checkBindingAction detects potential interference from other addons using SetOverrideBinding()
			text = key1;
		elseif (key2 and checkBindingAction(key2, id, (self.actionName and (self.actionName .. self.buttonNum)) or "CLICK CT_BarModActionButton" .. id .. ":Button31")) then
			text = key2;
		else
			return;
		end
	end

	if (not cachedBindingText[text]) then			-- multiple gsub queries are expensive, so cache the results to improve performance
		local uncachedText = text;
		uncachedText = uncachedText:gsub("(.-)MOUSEWHEELUP(.-)", "%1WU%2");
		uncachedText = uncachedText:gsub("(.-)MOUSEWHEELDOWN(.+)", "%1WD%2");
		uncachedText = uncachedText:gsub("(.-)BUTTON(.+)", "%1B%2");
		uncachedText = uncachedText:gsub("(.-)SHIFT%-(.+)", "%1S-%2");
		uncachedText = uncachedText:gsub("(.-)CTRL%-(.+)", "%1C-%2");
		uncachedText = uncachedText:gsub("(.-)ALT%-(.+)", "%1A-%2");
		cachedBindingText[text] = uncachedText;
	end
	return cachedBindingText[text];
end

function useButton:getSkin()
	return self.button.skinNumber or 1;
end

function useButton:setSkin(skinNumber)
	self.button.skinNumber = skinNumber or 1;
end

function useButton:reskin()
	self:applySkin();
	self:update();
end

-- These are the objects in the skin that we are using
-- for the CT action buttons.
local skinObjects = {
	-- object key, skin key, object type
	{ "backdrop", "Backdrop", "tx" },
	{ "icon", "Icon", "tx" },
	{ "border", "Border", "tx" },
	{ "flash", "Flash", "tx" },
	{ "normalTexture", "Normal", "tx" },
	{ "pushedTexture", "Pushed", "tx" },
	{ "highlightTexture", "Highlight", "tx" },
	{ "checkedTexture", "Checked", "tx" },
	{ "cooldown", "Cooldown", "cd" },
	{ "name", "Name", "fs" },
	{ "count", "Count", "fs" },
	{ "hotkey", "HotKey", "fs" },
};

local DEFAULT_TEX_COORD = {0, 1, 0, 1};
function useButton:applySkin()
	-- Apply a CT skin to the button.
	local object, objectKey, objectSkin, objectType;
	local font, size, flags;

	local button = self.button;
	local skinData = module:getSkinData(self:getSkin());

	-- We need to do enough that we counter anything that may
	-- have been done to the buttons, textures, etc by Masque.
	for key, value in ipairs(skinObjects) do
		objectKey = value[1];
		objectSkin = skinData[value[2]];
		objectType = value[3];

		object = button[objectKey];

		if (objectType == "tx") then
			object:SetWidth(objectSkin.Width or 36);
			object:SetHeight(objectSkin.Height or 36);

			if (objectKey == "normalTexture") then
				-- For the normal texture, call the button object's
				-- setNormalTexture method.
				--
				-- Our texture (button.normalTexture) is still the
				-- button's normal texture.
				--
				-- Masque hides our texture and shows its texture,
				-- but it does not change which texture is associated with
				-- the button's normal texture.
				--
				-- If Masque is loaded, this will also ensure a flag that
				-- Masque maintains on the button is updated.
				self:setNormalTexture(objectSkin.Texture or "");  -- Assign texture filename.
			else
				object:SetTexture(objectSkin.Texture or "");  -- Assign texture filename.
			end

			object:SetTexCoord(unpack(objectSkin.TexCoords or DEFAULT_TEX_COORD));
			object:SetDrawLayer(objectSkin.__CTBM__DrawLayer or "ARTWORK", objectSkin.__CTBM__SubLevel or 0)
			object:SetBlendMode(objectSkin.BlendMode or "BLEND");
			object:ClearAllPoints();
			object:SetPoint("CENTER", button, "CENTER", objectSkin.OffsetX or 0, objectSkin.OffsetY or 0);

			if (objectSkin.__CTBM__VertexColor) then
				object:SetVertexColor(unpack(objectSkin.Color or objectSkin.__CTBM__VertexColor));
			end

		elseif (objectType == "cd") then
			object:SetWidth(objectSkin.Width or 36);
			object:SetHeight(objectSkin.Height or 36);
			object:ClearAllPoints();
			object:SetPoint("CENTER", button, "CENTER", objectSkin.OffsetX or 0, objectSkin.OffsetY or 0);
			-- Masque puts the cooldown at one level below the button.
			-- We need it to be one level above the button.
			object:SetFrameLevel(button:GetFrameLevel()+1);

		elseif (objectType == "fs") then
			font, size, flags = objectSkin.__CTBM__Font:GetFont();
			object:SetFont(font, size, flags);
			object:SetJustifyH(objectSkin.JustifyH or "RIGHT");
			object:SetJustifyV(objectSkin.JustifyV or "MIDDLE");
			object:SetDrawLayer(objectSkin.__CTBM__DrawLayer or "OVERLAY", objectSkin.__CTBM__SubLevel or 0);
			object:SetWidth(objectSkin.Width or 36);
			object:SetHeight(objectSkin.Height or 36);
			object:ClearAllPoints();

			-- Use our saved SetPoint reference since Masque replaces .SetPoint with
			-- a function that does nothing.
			object:__CTBM__SetPoint(objectSkin.__CTBM__Anchor or "TOPLEFT", button, objectSkin.__CTBM__Relative or "TOPLEFT", objectSkin.OffsetX or 0, objectSkin.OffsetY or 0);

			if (objectSkin.__CTBM__VertexColor) then
				object:SetVertexColor(unpack(objectSkin.Color or objectSkin.__CTBM__VertexColor));
			end
		end
		if (objectSkin.__CTBM__Hide == true) then
			object:Hide();
		elseif (objectSkin.__CTBM__Hide == false) then
			object:Show();
		end
	end

	-- Show/hide the CT backdrop texture
	self:updateBackdrop();

	-- Masque parents the icon texture to a frame they create.
	-- Make sure the icon is parented to our button.
	button.icon:SetParent(button);
	
	-- Update the textures used for the spell alert overlay glows.
	-- The CT_BarMod skins only use the square shape, so we can pass nil
	-- for the Glow and Ants textures to use the default square textures.
	module:skinOverlayGlow(button, nil, nil);
end

------------------------
-- Button Handlers

-- PreClick
function useButton:preclick()

--[[
	-- This is not needed when using "type" == "click" and "clickbutton" == PossessButton2.
	-- We do need it if we use type == nil instead.
	if (self.actionMode == "cancel") then
		if ( UnitControllingVehicle("player") and CanExitVehicle() ) then
			VehicleExit();
		end
	end
--]]

end

-- PostClick
function useButton:postclick()
	if ( not self.checked ) then
		self.button:SetChecked(false);
	end
	self:updateState();
end

-- OnDragStart
function useButton:ondragstart(button, actionId, kind, value, ...)
	-- Parameters are different than a normal OnDragStart handler.
	-- This is being called before the secure handler
	-- actually picks up the action. To prevent :updateFlash
	-- and :updateState from continuing to flash the button
	-- and show it as checked, we need to force both of those
	-- states to false.
	-- print("ondragstart", button, actionId, kind, value, ...);
	self:updateFlash(false);
	self:updateState(false);
end

-- OnReceiveDrag
function useButton:onreceivedrag(actionId, kind, value, ...)
	-- Parameters are different than a normal OnReceiveDrag handler.
	-- We don't need to do anything when the action gets placed.
	-- Other things update it.
	-- print("onreceivedrag", actionId, kind, value, ...);
end

-- OnEnter
function useButton:onenter()
	self:updateFlyout();
end

-- OnLeave
function useButton:onleave()
	self:updateFlyout();
end

------------------------
-- Flash Handling

local flashingButtons;

-- Toggles flashing on a button
local function toggleFlash(object, enable)
	local flash = object.button.flash;
	
	if ( enable ~= nil ) then
		if ( enable ) then
			flash:Show();
		else
			flash:Hide();
		end
	else
		if ( not flash:IsShown() ) then
			flash:Show();
		else
			flash:Hide();
		end
	end
end

-- Periodic flash updater
local function flashUpdater()
	if ( flashingButtons ) then
		for key, value in pairs(flashingButtons) do
			toggleFlash(key);
		end
	end
end

-- Start Flashing
function useButton:startFlash()
	if ( not flashingButtons ) then
		flashingButtons = { };
	end
	
	self.flashing = true;
	toggleFlash(self, true);
	flashingButtons[self] = true;
	
	module:unschedule(flashUpdater, true);
	module:schedule(0.5, true, flashUpdater);
end

-- Stop Flashing
function useButton:stopFlash()
	if ( flashingButtons and self.flashing ) then
		self.flashing = nil;
		flashingButtons[self] = nil;
		toggleFlash(self, false);
		if ( not next(flashingButtons) ) then
			module:unschedule(flashUpdater, true);
		end
	end
end

function useButton:updateSummonPets()
	local actionType, id = GetActionInfo(self.actionId);
	if (actionType == "summonpet") then
		local texture = GetActionTexture(self.actionId);
		if (texture) then
			self.button.icon:SetTexture(texture);
		end
	end
end

--------------------------------------------
-- Event Handlers

local loginFinished, updateAfterLogin = false, false;

local function eventHandler_UpdateAll(event, unit)
	if (event ~= "UNIT_INVENTORY_CHANGED") then
		actionButtonList:update();
	elseif (unit == "player") then
		if (loggedFinished) then
			actionButtonList:update();
		else
			updateAfterLogin = true;	-- UNIT_INVENTORY_CHANGED happens several times during a fresh login.  This delays the call until one frame after PLAYER_LOGIN
		end
	end
end

local function eventHandler_PlayerLogin()

	-- see eventHandler_UpdateBindings()
	wipeBindingCaches();
	module.setActionBindings();
	actionButtonList:updateBinding();

	-- see eventHandler_UpdateAll()
	C_Timer.After(0, function()
		if (updateAfterLogin) then
			actionButtonList:update();
		end
		loginFinished = true;
	end);
end



--local function eventHandler_HideGrid()
--	actionButtonList:hideGrid();
--	actionButtonList:updateVisibility();
--end
--
--local function eventHandler_ShowGrid()
--	actionButtonList:showGrid();
--	actionButtonList:updateVisibility();
--end

local function eventHandler_UpdateState()
	actionButtonList:updateState();
end

local function eventHandler_UpdateStateVehicle(event, arg1)
	if (arg1 == "player") then		
		-- Put correct keybinds labels on all the buttons after entering or leaving a vehicle
		if (event == "UNIT_ENTERING_VEHICLE") then
			module.setActionBindings(event);
			wipeBindingCaches();
			actionButtonList:updateBinding();
		elseif (event == "UNIT_ENTERED_VEHICLE") then
			eventHandler_UpdateState();
			-- Update the buttons to make sure the exit vehicle
			-- button is properly shown if CanExitVehicle().
			actionButtonList:update();
		elseif (event == "UNIT_EXITED_VEHICLE") then
			eventHandler_UpdateState();
			actionButtonList:update();
			module.setActionBindings(event);
			wipeBindingCaches();
			actionButtonList:updateBinding();
		end
	end
end

local function eventHandler_UpdateStateCompanion(event, arg1)
	if (arg1 == "MOUNT") then
		eventHandler_UpdateState();
	end
end

local function eventHandler_UpdateCount()
	actionButtonList:updateCount();
end

local function eventHandler_UpdateCooldown()
	actionButtonList:updateUsable();
	actionButtonList:updateCount();
	actionButtonList:updateCooldown();
	
end

local function eventHandler_UpdateUsable()
	actionButtonList:updateUsable();
	actionButtonList:updateCooldown();
end

local function eventHandler_UpdateBindings()
	wipeBindingCaches();
	module.setActionBindings();
	actionButtonList:updateBinding();
	
	-- also see eventHandler_PlayerLogin();
end

local function eventHandler_CheckRepeat()
	actionButtonList:updateFlash();
end

local function eventHandler_ShowOverlayGlow(event, arg1)
	actionButtonList:showOverlayGlow(arg1);
end

local function eventHandler_HideOverlayGlow(event, arg1)
	actionButtonList:hideOverlayGlow(arg1);
end

local function eventHandler_updateSummonPets()
	actionButtonList:updateSummonPets();
end

-- Target changed
local function rangeTargetUpdater()
	actionButtonList:updateBinding();
	if ( UnitExists("target")) then
		actionButtonList:updateRange()
	else
		actionButtonList:clearRange();
	end
	if ( colorLack ) then
		actionButtonList:updateUsable();
	end
end

-- Range checker
local function rangeUpdater()
	if UnitExists("target") then
		actionButtonList:updateRange();
	end
end

-- Formerly called every 0.5 sec as part of rangeUpdater(), but now broken away to experiment with calling every 5.0 sec
-- In a future version, this should be removed completely to further improve CPU usage
local function bindingUpdator()
	actionButtonList:updateBinding();
end

--------------------------------------------
-- Preset Groups

function module:setupPresetGroups()
	local actionNames = {};
	actionNames[3] = "MULTIACTIONBAR3BUTTON";  -- Right bar
	actionNames[4] = "MULTIACTIONBAR4BUTTON";  -- Right bar 2
	actionNames[5] = "MULTIACTIONBAR2BUTTON";  -- Bottom Right bar
	actionNames[6] = "MULTIACTIONBAR1BUTTON";  -- Bottom Left bar
	actionNames[12] = "ACTIONBUTTON";  -- Action bar
	for groupNum = 1, module.maxBarNum do
		local groupId = module.GroupNumToId(groupNum);
		local base;
		if (groupId == module.actionBarId) then
			base = 0;
		else
			base = groupNum - 1;
		end
		local actionId, buttonId, object;
		for count = 1, 12, 1 do
			actionId = base * 12 + count;
			buttonId = (groupNum - 1) * 12 + count;
			object = useButton:new(buttonId, actionId, groupId, count);
			object.actionName = actionNames[groupNum];
			self:addObjectToGroup(object, object.groupId);
		end
		self:registerPagingStateDriver(object.groupId);
	end
end

--------------------------------------------
-- Default-Bar additions

local function updateBlizzardButtons(func)
	for i = 1, 12 do
		func(_G["ActionButton" .. i]);
		func(_G["MultiBarLeftButton" .. i]);
		func(_G["MultiBarRightButton" .. i]);
		func(_G["MultiBarBottomLeftButton" .. i]);
		func(_G["MultiBarBottomRightButton" .. i]);
	end
end

do
	local function setBlizzardButtonAttributes(button)
		local action = ActionButton_GetPagedID(button)
		button.hasAction = HasAction(action);
		button.hasRange = ActionHasRange(action);
		button.isConsumable = IsConsumableAction(action);
		button.isStackable = IsStackableAction(action);
		button.isItem = IsItemAction(action);
	end
		
	local function hookBlizzardButtonAttributes(button)
		-- in case something was dragged to this slot
		button:HookScript("OnReceiveDrag", setBlizzardButtonAttributes);
		
		-- in case something was dragged from this slot
		button:HookScript("OnDragStop", setBlizzardButtonAttributes);
		
		-- when the buttons first appear!
		button:HookScript("OnShow", setBlizzardButtonAttributes);
	end
	
	updateBlizzardButtons(hookBlizzardButtonAttributes);
end

-----
-- Out of Range (icon coloring)
-----
do
	local isReset;

	local function CT_BarMod_ActionButton_FadeOutOfRange(self)
		if (defbarShowRange) then
			if ( colorLack and self.hasAction and self.hasRange and IsActionInRange(ActionButton_GetPagedID(self)) == false ) then
				local icon = self.icon;		-- _G[self:GetName().."Icon"];
				if ( colorLack == 2 ) then
					icon:SetVertexColor(0.5, 0.5, 0.5);
				else
					icon:SetVertexColor(0.8, 0.4, 0.4);
				end
			else
				ActionButton_UpdateUsable(self);
			end
		end
	end
	
	local function CT_BarMod_ActionButton_StartFadeTicker(self)
		self.ctFadeTicker = self.ctFadeTicker or C_Timer.NewTicker(0.25, function() CT_BarMod_ActionButton_FadeOutOfRange(self); end);
	end
	
	local function CT_BarMod_ActionButton_CancelFadeTicker(self)
		if (self.ctFadeTicker) then
			self.ctFadeTicker:Cancel();
			self.ctFadeTicker = nil;
		end
	end

	updateBlizzardButtons(function(button)
		button:HookScript("OnEnter", CT_BarMod_ActionButton_FadeOutOfRange);
		button:HookScript("OnShow", CT_BarMod_ActionButton_StartFadeTicker);
		button:HookScript("OnHide", CT_BarMod_ActionButton_CancelFadeTicker);
	end);
	
	local function CT_BarMod_ActionButton_ResetRange(self)
		-- Reset button to Blizzard default state.

		ActionButton_UpdateUsable(self);
	end

	function CT_BarMod_UpdateActionButtonRange()
		if (defbarShowRange) then
			updateBlizzardButtons(CT_BarMod_ActionButton_FadeOutOfRange);
			isReset = nil;
		elseif (isReset) then
			return;
		else
			updateBlizzardButtons(CT_BarMod_ActionButton_ResetRange);
			isReset = true;
		end
	end
	
	module:regEvent("PLAYER_TARGET_CHANGED", CT_BarMod_UpdateActionButtonRange);
	module:regEvent("ACTIONBAR_PAGE_CHANGED", CT_BarMod_UpdateActionButtonRange);
end

-----
-- Cooldown Count
-----
do
	local isReset = true;

	local function CT_BarMod_ActionButton_UpdateCooldown(self)

		local actionId = ActionButton_GetPagedID(self);
		local cooldown = self.cooldown;

		-- Set up variables we need in our cooldown handler
		cooldown.object = self;
		self.actionId = actionId;

		if actionId then
			local start, duration, enable = GetActionCooldown(actionId);
			start, duration = ctSafe(start, 0), ctSafe(duration, 0);	-- secret in combat -> 0 (cooldown not shown)
			if ( start > 0 and (enable and enable ~= 0) ) then	-- enable is a boolean in Midnight (was 1/0)
				startCooldown(cooldown, start, duration);
				if (not displayCount) then
					hideCooldown(cooldown);
				end
			else
				hideCooldown(cooldown);
			end
		else
			local i = 1;
	 		local button = _G["SpellFlyoutButton"..i];
	 		while (button and button:IsShown()) do
	 			local start, duration, enable = GetSpellCooldown(button.spellID);
				start, duration = ctSafe(start, 0), ctSafe(duration, 0);	-- secret in combat -> 0
				if ( start > 0 and duration > 0 and (enable and enable ~= 0) ) then	-- enable is a boolean in Midnight (was 1/0)
					startCooldown(cooldown, start, duration);
					if (not displayCount) then
						hideCooldown(cooldown);
					end
				else
					hideCooldown(cooldown);
				end
	 			i = i + 1;
	 			button = _G["SpellFlyoutButton"..i];
	 		end
		end
	end

	local function CT_BarMod_ActionButton_ResetCooldown(self)
		-- Reset button to Blizzard default state.

		local actionId = ActionButton_GetPagedID(self);
		local cooldown = self.cooldown;

		-- Set up variables we need in our cooldown handler
		cooldown.object = self;
		self.actionId = actionId;

		stopCooldown(cooldown);
	end

	function CT_BarMod_UpdateActionButtonCooldown()
		if (defbarShowCooldown) then
			updateBlizzardButtons(CT_BarMod_ActionButton_UpdateCooldown);
			isReset = nil;
		elseif (isReset) then
			return;
		else
			updateBlizzardButtons(CT_BarMod_ActionButton_ResetCooldown);
			isReset = true;
		end
	end
	
	module:regEvent("ACTIONBAR_UPDATE_COOLDOWN", CT_BarMod_UpdateActionButtonCooldown);
	module:regEvent("ACTIONBAR_PAGE_CHANGED", CT_BarMod_UpdateActionButtonCooldown);
end

-----
-- Cooldown Recharge
-----
do
	-- StartChargeCooldown is removed in modern clients (Midnight); only hook it where it still exists,
	-- otherwise the load-time error here aborts the rest of this file (leaving useEnable/useUpdate undefined).
	if (StartChargeCooldown) then
		hooksecurefunc("StartChargeCooldown", function(parent, chargeStart)
			if (chargeStart ~= 0 and displayRecharge == false and defbarShowRecharge) then
				ClearChargeCooldown(parent)
			end
		end)
	end
end

-----
-- Hotkeys (key bindings, range dot)
-----
do
	local isReset = true;

	local function CT_BarMod_ActionButton_UpdateHotkeys(self, ...)
		if (defbarShowBindings) then
			local hotkey = self.HotKey;		-- _G[self:GetName().."HotKey"];			
			if (displayBindings and displayRangeDot) then
				-- Default behavior of standard UI is to display both.
				hotkey:SetAlpha(1);
			elseif (displayRangeDot and hotkey:GetText() == rangeIndicator) then
				hotkey:SetAlpha(1);
			elseif (displayBindings and hotkey:GetText() ~= rangeIndicator) then
				hotkey:SetAlpha(1);
			else
				hotkey:SetAlpha(0);
			end
		end
	end
	if (ActionBarActionButtonMixin and ActionBarActionButtonMixin.UpdateHotkeys) then
		-- Shadowlands 9.0
		hooksecurefunc(ActionBarActionButtonMixin, "UpdateHotkeys", CT_BarMod_ActionButton_UpdateHotkeys);
	else
		-- 8.x and earlier
		hooksecurefunc("ActionButton_UpdateHotkeys", CT_BarMod_ActionButton_UpdateHotkeys);
	end

	local function CT_BarMod_ActionButton_ResetHotkeys(self)
		-- Reset button to Blizzard default state.

		local hotkey = self.HotKey;		-- _G[self:GetName().."HotKey"];
		hotkey:SetAlpha(1);
	end

	function CT_BarMod_UpdateActionButtonHotkeys()
		if (defbarShowBindings) then
			updateBlizzardButtons(CT_BarMod_ActionButton_UpdateHotkeys);
			isReset = nil;
		elseif (isReset) then
			return;
		else
			updateBlizzardButtons(CT_BarMod_ActionButton_ResetHotkeys);
			isReset = true;
		end
	end
end

-----
-- Action text (macro names)
-----
do
	local isReset = true;
	
	local dummyFunc = CreateFrame("Frame"):CreateFontString(nil, "ARTWORK").SetText;

	local function CT_BarMod_ActionButton_HookActionText(button)
		hooksecurefunc(button.Name, "SetText", function(text)
			-- It's only appropriate to overwrite what Blizzard did in very narrow circumstances.
			if (defbarShowActionText and displayActionText == false and text ~= "" and button.isConsumable ~= true and button.isStackable ~= true) then
				dummyFunc(button.Name, "")
			end
		end);
	end

	local function CT_BarMod_ActionButton_UpdateActionText(self)
		-- Unlike the hook, it may be necessary to restore deleted text when the user changes settings
		if (defbarShowActionText) then
			-- isConsumable and isStackable may be nil instead of false if the bar was disabled during a /reload and the user later chooses to enable it in the settings.
			if (displayActionText == false and self.isConsumable ~= true and self.isStackable ~= true) then
				dummyFunc(self.Name, "")
			else
				dummyFunc(self.Name, GetActionText(self.action))
			end
		end
	end

	local function CT_BarMod_ActionButton_ResetActionText(self)
		-- Reset button to Blizzard default state.

		local name = self.Name;		--  _G[self:GetName() .. "Name"];
		if (name) then
			local actionId = self.action;
			if ( not (self.isConsumable or self.isStackable) ) then
				name:SetText(GetActionText(actionId));
			else
				name:SetText("");
			end
		end
	end

	function CT_BarMod_UpdateActionButtonActionText()
		if (defbarShowActionText) then
			updateBlizzardButtons(CT_BarMod_ActionButton_UpdateActionText);
			isReset = nil;
		elseif (isReset) then
			return;
		else
			updateBlizzardButtons(CT_BarMod_ActionButton_ResetActionText);
			isReset = true;
		end
	end
	
	updateBlizzardButtons(CT_BarMod_ActionButton_HookActionText);
end

-----
-- Unit
-----

do
	local isReset, deferredForCombat = true, false;

	local function CT_BarMod_ActionButton_UpdateUnitAttributes(self, ...)
		-- set the attributes to custom values (by default, these values are 'nil' so this won't do anything)
		self:SetAttribute("unit1", unitAttribute1);
		self:SetAttribute("unit2", unitAttribute2);
		self:SetAttribute("unit3", unitAttribute3);
	end

	local function CT_BarMod_ActionButton_ResetUnitAttributes(self)
		-- Reset button to Blizzard default state.
		self:SetAttribute("unit1", nil);
		self:SetAttribute("unit2", nil);
		self:SetAttribute("unit3", nil);
	end

	function CT_BarMod_UpdateActionButtonUnitAttributes()
		if (InCombatLockdown()) then
			deferredForCombat = true;
		else
			if (defbarSetUnitAttributes) then
				updateBlizzardButtons(CT_BarMod_ActionButton_UpdateUnitAttributes);
				isReset = nil;
			elseif (isReset) then
				return;
			else
				updateBlizzardButtons(CT_BarMod_ActionButton_ResetUnitAttributes);
				isReset = true;
			end
		end
	end
	
	module:regEvent("PLAYER_LOGIN", CT_BarMod_UpdateActionButtonUnitAttributes);
	module:regEvent("PLAYER_REGEN_ENABLED", function()
		if (deferredForCombat) then
			deferredForCombat = nil;
			CT_BarMod_UpdateActionButtonUnitAttributes();
		end
	end);
end

-----
-- Tooltips
-----
do
	local function CT_BarMod_ActionButton_SetTooltip(self, ...)
		if (defbarHideTooltip and hideTooltip) then
			GameTooltip:Hide();
		end
	end
	if (ActionBarActionButtonMixin and ActionBarActionButtonMixin.SetTooltip) then
		-- Shadowlands 9.0
		hooksecurefunc(ActionBarActionButtonMixin, "SetTooltip", CT_BarMod_ActionButton_SetTooltip);
	else
		-- 8.x and earlier
		hooksecurefunc("ActionButton_SetTooltip", CT_BarMod_ActionButton_SetTooltip);
	end
end

--------------------------------------------
-- Update Initialization

local function combatFlagger(event)
	inCombat = ( event == "PLAYER_REGEN_DISABLED" );
	if (event == "PLAYER_REGEN_ENABLED") then
		if (module.needSetActionBindings) then
			wipeBindingCaches();			-- clears caches in this file
			module:clearKeyBindingsCache();		-- clears caches in _KeyBindings		
			module.setActionBindings();		-- sets override bindings in _KeyBindings
			actionButtonList:updateBinding();	-- sets labels on all bars in this file
		end
		if (needSetUnitTargetingAttributes) then
			needSetUnitTargetingAttributes = false;
			actionButtonList:updateUnitAttributes();
		end
	end
end

local useButtonMeta = { __index = useButton };
module.useButtonMeta = useButtonMeta;

module.useEnable = function(self)
	self:regEvent("PLAYER_ENTERING_WORLD", eventHandler_UpdateAll);
	self:regEvent("UPDATE_SHAPESHIFT_FORM", eventHandler_UpdateAll);
	self:regEvent("UNIT_INVENTORY_CHANGED", eventHandler_UpdateAll);
	self:regEvent("PET_STABLE_UPDATE", eventHandler_UpdateAll);
	self:regEvent("PET_STABLE_SHOW", eventHandler_UpdateAll);
	--self:regEvent("ACTIONBAR_HIDEGRID", eventHandler_HideGrid);
	--self:regEvent("ACTIONBAR_SHOWGRID", eventHandler_ShowGrid);
	self:regEvent("ACTIONBAR_UPDATE_STATE", eventHandler_UpdateState);
	self:regEvent("ACTIONBAR_UPDATE_COOLDOWN", eventHandler_UpdateCooldown);
	self:regEvent("ACTIONBAR_UPDATE_USABLE", eventHandler_UpdateUsable);
	self:regEvent("UPDATE_INVENTORY_ALERTS", eventHandler_UpdateUsable);
	self:regEvent("TRADE_SKILL_SHOW", eventHandler_UpdateState);
	self:regEvent("TRADE_SKILL_CLOSE", eventHandler_UpdateState);
	self:regEvent("UPDATE_BINDINGS", eventHandler_UpdateBindings);
	self:regEvent("PLAYER_LOGIN", eventHandler_PlayerLogin);
	self:regEvent("PLAYER_ENTER_COMBAT", eventHandler_CheckRepeat);
	self:regEvent("PLAYER_LEAVE_COMBAT", eventHandler_CheckRepeat);
	self:regEvent("STOP_AUTOREPEAT_SPELL", eventHandler_CheckRepeat);
	self:regEvent("START_AUTOREPEAT_SPELL", eventHandler_CheckRepeat);
	self:regEvent("PLAYER_TARGET_CHANGED", rangeTargetUpdater);
	self:regEvent("PLAYER_REGEN_ENABLED", combatFlagger);
	self:regEvent("PLAYER_REGEN_DISABLED", combatFlagger);
	self:regEvent("SPELL_UPDATE_CHARGES", eventHandler_UpdateCount);
	self:regEvent("LOSS_OF_CONTROL_UPDATE", eventHandler_UpdateCooldown);
	if module:getGameVersion() >= 3 then
		self:regEvent("UNIT_ENTERING_VEHICLE", eventHandler_UpdateStateVehicle);
		self:regEvent("UNIT_ENTERED_VEHICLE", eventHandler_UpdateStateVehicle);
		self:regEvent("UNIT_EXITED_VEHICLE", eventHandler_UpdateStateVehicle);
		self:regEvent("UPDATE_VEHICLE_ACTIONBAR", eventHandler_UpdateAll);
		self:regEvent("UPDATE_OVERRIDE_ACTIONBAR", eventHandler_UpdateAll);
		self:regEvent("UPDATE_POSSESS_BAR", eventHandler_UpdateAll);
		self:regEvent("UPDATE_MULTI_CAST_ACTIONBAR", eventHandler_UpdateAll);
		self:regEvent("COMPANION_UPDATE", eventHandler_UpdateStateCompanion);
	end
	if module:getGameVersion() >= 4 then
		self:regEvent("ARCHAEOLOGY_CLOSED", eventHandler_UpdateState);
		self:regEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", eventHandler_ShowOverlayGlow);
		self:regEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", eventHandler_HideOverlayGlow);
	end
	if module:getGameVersion() >= 5 then
		self:regEvent("UPDATE_SUMMONPETS_ACTION", eventHandler_updateSummonPets);
	end
	self:schedule(0.25, true, rangeUpdater); -- originally 0.5 sec, but setting at 0.25 sec to more closely match the Blizzard default bars
	self:schedule(5, true, bindingUpdater);  -- it is unclear if this is truly even necessary.  It used to be every 0.5 sec.  Now experimenting with every 5 sec, after migrating range-checking parts into a separate function
end

module.useDisable = function(self)
	self:unregEvent("PLAYER_ENTERING_WORLD", eventHandler_UpdateAll);
	self:unregEvent("UPDATE_SHAPESHIFT_FORM", eventHandler_UpdateAll);
	self:unregEvent("UNIT_INVENTORY_CHANGED", eventHandler_UpdateAll);
	self:unregEvent("PET_STABLE_UPDATE", eventHandler_UpdateAll);
	self:unregEvent("PET_STABLE_SHOW", eventHandler_UpdateAll);
	--self:unregEvent("ACTIONBAR_HIDEGRID", eventHandler_HideGrid);
	--self:unregEvent("ACTIONBAR_SHOWGRID", eventHandler_ShowGrid);
	self:unregEvent("ACTIONBAR_UPDATE_COOLDOWN", eventHandler_UpdateCooldown);
	self:unregEvent("ACTIONBAR_UPDATE_STATE", eventHandler_UpdateState);
	self:unregEvent("ACTIONBAR_UPDATE_USABLE", eventHandler_UpdateUsable);
	self:unregEvent("UPDATE_INVENTORY_ALERTS", eventHandler_UpdateUsable);
	self:unregEvent("TRADE_SKILL_SHOW", eventHandler_UpdateState);
	self:unregEvent("TRADE_SKILL_CLOSE", eventHandler_UpdateState);
	self:unregEvent("UPDATE_BINDINGS", eventHandler_UpdateBindings);
	self:unregEvent("PLAYER_LOGIN", eventHandler_PlayerLogin);
	self:unregEvent("PLAYER_ENTER_COMBAT", eventHandler_CheckRepeat);
	self:unregEvent("PLAYER_LEAVE_COMBAT", eventHandler_CheckRepeat);
	self:unregEvent("STOP_AUTOREPEAT_SPELL", eventHandler_CheckRepeat);
	self:unregEvent("START_AUTOREPEAT_SPELL", eventHandler_CheckRepeat);
	self:unregEvent("PLAYER_TARGET_CHANGED", rangeTargetUpdater);
	self:unregEvent("PLAYER_REGEN_ENABLED", combatFlagger);
	self:unregEvent("PLAYER_REGEN_DISABLED", combatFlagger);
	self:unregEvent("SPELL_UPDATE_CHARGES", eventHandler_UpdateCount);
	self:unregEvent("LOSS_OF_CONTROL_UPDATE", eventHandler_UpdateCooldown);
	if module:getGameVersion() >= 3 then
		self:unregEvent("UNIT_ENTERING_VEHICLE", eventHandler_UpdateStateVehicle);
		self:unregEvent("UNIT_ENTERED_VEHICLE", eventHandler_UpdateStateVehicle);
		self:unregEvent("UNIT_EXITED_VEHICLE", eventHandler_UpdateStateVehicle);
		self:unregEvent("UPDATE_VEHICLE_ACTIONBAR", eventHandler_UpdateAll);
		self:unregEvent("UPDATE_OVERRIDE_ACTIONBAR", eventHandler_UpdateAll);
		self:unregEvent("UPDATE_POSSESS_BAR", eventHandler_UpdateAll);
		self:unregEvent("UPDATE_MULTI_CAST_ACTIONBAR", eventHandler_UpdateAll);
		self:unregEvent("COMPANION_UPDATE", eventHandler_UpdateStateCompanion);		
	end
	if module:getGameVersion() >= 4 then
		self:unregEvent("ARCHAEOLOGY_CLOSED", eventHandler_UpdateState);
		self:unregEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", eventHandler_ShowOverlayGlow);
		self:unregEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", eventHandler_HideOverlayGlow);
	end
	if module:getGameVersion() >= 5 then		
		self:unregEvent("UPDATE_SUMMONPETS_ACTION", eventHandler_updateSummonPets);
	end
	self:unschedule(rangeUpdater, true);
	self:unschedule(bindingUpdater, true);
end

module.useUpdate = function(self, optName, value)
	if ( optName == "colorLack" ) then
		if ( value == 3 ) then
			value = false;
		end
		colorLack = value;
		actionButtonList:updateUsable();

	elseif ( optName == "actionBindings" ) then
		actionBindings = value ~= false;
		wipeBindingCaches();
		module.setActionBindings();
		actionButtonList:updateBinding();

	elseif ( optName == "bar3Bindings" ) then
		bar3Bindings = value ~= false;
		wipeBindingCaches();
		module.setActionBindings();
		actionButtonList:updateBinding();

	elseif ( optName == "bar4Bindings" ) then
		bar4Bindings = value ~= false;
		wipeBindingCaches();
		module.setActionBindings();
		actionButtonList:updateBinding();

	elseif ( optName == "bar5Bindings" ) then
		bar5Bindings = value ~= false;
		wipeBindingCaches();
		module.setActionBindings();
		actionButtonList:updateBinding();

	elseif ( optName == "bar6Bindings" ) then
		bar6Bindings = value ~= false;
		wipeBindingCaches();
		module.setActionBindings();
		actionButtonList:updateBinding();

	elseif ( optName == "displayBindings" ) then
		displayBindings = value;
		actionButtonList:updateBinding();
		CT_BarMod_UpdateActionButtonHotkeys();

	elseif ( optName == "displayRangeDot" ) then
		displayRangeDot = value;
		actionButtonList:updateBinding();
		CT_BarMod_UpdateActionButtonHotkeys();

	elseif ( optName == "displayActionText" ) then
		displayActionText = value;
		actionButtonList:update();
		CT_BarMod_UpdateActionButtonActionText();
		
	elseif ( optName == "unitAttribute1" ) then
		unitAttribute1 = UNIT_ATTRIBUTES[value];
		actionButtonList:updateUnitAttributes();
		CT_BarMod_UpdateActionButtonUnitAttributes();
		
	elseif ( optName == "unitAttribute2" ) then
		unitAttribute2 = UNIT_ATTRIBUTES[value];
		actionButtonList:updateUnitAttributes();
		CT_BarMod_UpdateActionButtonUnitAttributes();	
		
	elseif ( optName == "unitAttribute3" ) then
		unitAttribute3 = UNIT_ATTRIBUTES[value];
		actionButtonList:updateUnitAttributes();
		CT_BarMod_UpdateActionButtonUnitAttributes();
			
	elseif ( optName == "displayCount" ) then
		displayCount = value;
		actionButtonList:updateCooldown();

	elseif ( optName == "displayRecharge" ) then
		displayRecharge = value;
		actionButtonList:updateCooldown();

	elseif ( optName == "hideGlow" ) then
		hideGlow = value;
		actionButtonList:updateOverlayGlow();

	elseif ( optName == "buttonLock" ) then
		buttonLock = value;
		actionButtonList:updateLock();

	elseif ( optName == "buttonLockKey" ) then
		buttonLockKey = value or 3;
		actionButtonList:updateLock();

	elseif ( optName == "hideGrid" ) then
		hideGrid = value
		if hideGrid then
			actionButtonList:hideGrid()
			if MultiBar7 then
				module:afterCombat(function()
					MultiBar7Button12:SetAttribute("ctForceHideGrid", 1)
					MultiBar7Button12:SetAttribute("showgrid", 0)
				end)
			end
		else
			actionButtonList:showGrid()
			module:afterCombat(function()
				MultiBar7Button12:SetAttribute("ctForceHideGrid", 0)
				MultiBar7Button12:SetAttribute("showgrid", MultiBar7Button11:GetAttribute("showgrid"))
			end)
		end
		actionButtonList:update()

	elseif ( optName == "useNonEmptyNormal" ) then
		useNonEmptyNormal = value;
		actionButtonList:update();

	elseif ( optName == "backdropShow" ) then
		backdropShow = value;
		if (not module:usingMasque()) then
			actionButtonList:updateBackdrop();
		end

	elseif ( optName == "hideTooltip" ) then
		hideTooltip = value;

	elseif ( optName == "defbarShowRange" ) then
		defbarShowRange = value;
		CT_BarMod_UpdateActionButtonRange();

	elseif ( optName == "defbarShowCooldown" ) then
		defbarShowCooldown = value;
		CT_BarMod_UpdateActionButtonCooldown();

	elseif ( optName == "defbarShowRecharge" ) then
		defbarShowRecharge = value;
		CT_BarMod_UpdateActionButtonCooldown();

	elseif ( optName == "defbarShowBindings" ) then
		defbarShowBindings = value;
		CT_BarMod_UpdateActionButtonHotkeys();

	elseif ( optName == "defbarShowActionText" ) then
		defbarShowActionText = value;
		CT_BarMod_UpdateActionButtonActionText();
		
	elseif ( optName == "defbarSetUnitAttributes" ) then
		defbarSetUnitAttributes = value;
		CT_BarMod_UpdateActionButtonUnitAttributes();

	elseif ( optName == "defbarHideTooltip" ) then
		defbarHideTooltip = value;
		
	elseif ( optName == "minimumCooldownToBling" ) then
		minimumCooldownToBling = value;

	elseif ( optName == "init" ) then
		colorLack = self:getOption("colorLack") or 1;
		if ( colorLack == 3 ) then
			colorLack = false;
		end
		actionBindings = self:getOption("actionBindings") ~= false;
		bar3Bindings = self:getOption("bar3Bindings") ~= false;
		bar4Bindings = self:getOption("bar4Bindings") ~= false;
		bar5Bindings = self:getOption("bar5Bindings") ~= false;
		bar6Bindings = self:getOption("bar6Bindings") ~= false;
		displayBindings = self:getOption("displayBindings") ~= false;
		displayRangeDot = self:getOption("displayRangeDot") ~= false;
		displayActionText = self:getOption("displayActionText") ~= false;
		module:regEvent("PLAYER_LOGIN", function()
			if (OmniCC) then
				displayCount = self:getOption("displayCount")
			else
				displayCount = self:getOption("displayCount") ~= false
			end
		end)
		displayRecharge = self:getOption("displayRecharge") ~= false;
		hideGlow = self:getOption("hideGlow");
		buttonLock = self:getOption("buttonLock");
		buttonLockKey = self:getOption("buttonLockKey") or 3;
		hideGrid = self:getOption("hideGrid")
		hideTooltip = self:getOption("hideTooltip");
		useNonEmptyNormal = self:getOption("useNonEmptyNormal");
		backdropShow = self:getOption("backdropShow");
		local left, right, middle =
			self:getOption("unitAttribute1"),
			self:getOption("unitAttribute2"),
			self:getOption("unitAttribute3");
		unitAttribute1 = left and UNIT_ATTRIBUTES[left];		-- 'nil' is the default value.
		unitAttribute2 = right and UNIT_ATTRIBUTES[right];
		unitAttribute3 = middle and UNIT_ATTRIBUTES[middle];

		defbarShowRange = module:getOption("defbarShowRange") ~= false;
		defbarShowCooldown = module:getOption("defbarShowCooldown") ~= false;
		defbarShowRecharge = module:getOption("defbarShowRecharge") ~= false;
		defbarShowBindings = module:getOption("defbarShowBindings") ~= false;
		defbarShowActionText = module:getOption("defbarShowActionText") ~= false;
		defbarSetUnitAttributes = module:getOption("defbarSetUnitAttributes") ~= false;
		defbarHideTooltip = module:getOption("defbarHideTooltip") ~= false;
		
		minimumCooldownToBling = module:getOption("minimumCooldownToBling") or 0

		if (hideGrid) then
			actionButtonList:hideGrid();
			if MultiBar7 then
				MultiBar7Button12:SetAttribute("ctForceHideGrid", 1)
			end
		else
			actionButtonList:showGrid();
			if MultiBar7 then
				MultiBar7Button12:SetAttribute("ctForceHideGrid", 0)
			end
		end
		actionButtonList:updateVisibility();

		CT_BarMod_UpdateActionButtonCooldown();
		CT_BarMod_UpdateActionButtonRange();
		CT_BarMod_UpdateActionButtonHotkeys();
		CT_BarMod_UpdateActionButtonActionText();
		CT_BarMod_UpdateActionButtonUnitAttributes();
	end
end
