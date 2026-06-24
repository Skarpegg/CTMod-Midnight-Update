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

local ceil = ceil;
local max = max;
local min = min;
local pairs = pairs;
local select = select;
local setmetatable = setmetatable;
local tinsert = tinsert;
local tremove = tremove;
local type = type;
local CanExitVehicle = CanExitVehicle;
local GetActionTexture = GetActionTexture;
local GetPossessInfo = GetPossessInfo;
local InCombatLockdown = InCombatLockdown;
local SetBinding = SetBinding;
local SetBindingClick = SetBindingClick;
local GetCVar = GetCVar or C_CVar.GetCVar;

-- End Local Copies
--------------------------------------------

-- Referenced at multiple locations
local newButtonMeta;
local currentMode;
local currentButtonClass;
local actionButton = { };
local actionButtonList = { };
--local savedButtons;

module.actionButtonList = actionButtonList;

module.maxBarNum = 12;  -- Maximum number of bars allowed
module.controlBarId = 11;  -- id number of the Control Bar
module.actionBarId = 12;  -- id number of the Action Bar

-------------------------------------------
-- Helpers

local currentHover;

local function updateHover(_, self)
	if ( not self ) then
		self = currentHover;
		if ( not self ) then
			return;
		end
	end
	if ( GetCVar("UberTooltips") == "1" ) then
		-- Note: GameTooltip_SetDefaultAnchor() will set Gametooltip.default to 1.
		-- If we end up not showing a tooltip (because no action associated
		-- with a button), then we want to make sure that the GameTooltip's OnHide
		-- script executes so that it can clear the GameTooltip.default value.
		-- To ensure the OnHide script is executed, set the tooltip to a single
		-- character right before calling GameTooltip:Hide(). That will force the
		-- tooltip to be shown if it wasn't already.
		GameTooltip_SetDefaultAnchor(GameTooltip, self);
	else
		local xthis = self:GetCenter();
		local xui = UIParent:GetCenter();
		if (xthis < xui) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		else
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		end
	end

	-- Note: If no action is associated with the button then no tooltip
	-- will be shown.
	if ( GameTooltip:SetAction(self.object.actionId) ) then
		currentHover = self;
	elseif (self.object.actionMode == "cancel") then
		if (CT_BarMod_SecureFrame:GetAttribute("hasVehicleUI")) then
			currentHover = nil;
		else
			local texture, name, enabled = GetPossessInfo(POSSESS_CANCEL_SLOT or 2);
			if (enabled) then
				GameTooltip:SetText(CANCEL or "Cancel", 1, 1, 1);
				GameTooltip:Show();
				currentHover = self;
			else
				GameTooltip:SetText(CANCEL or "Cancel", 0.7, 0.7, 0.7);
				GameTooltip:AddLine("Unable to cancel. You might be able to cancel a buff instead.", 1, 0.82, 0, true);
				GameTooltip:Show();
				currentHover = self;
			end
		end
	elseif (self.object.actionMode == "leave") then
		if (CT_BarMod_SecureFrame:GetAttribute("hasVehicleUI")) then
			if (CanExitVehicle()) then
				GameTooltip:SetText(LEAVE_VEHICLE or "Leave Vehicle", 1, 1, 1);
				GameTooltip:Show();
				currentHover = self;
			else
				GameTooltip:SetText(LEAVE_VEHICLE or "Leave Vehicle", 0.7, 0.7, 0.7);
				GameTooltip:AddLine("You cannot exit from the current vehicle.", 1, 0.82, 0, true);
				GameTooltip:Show();
				currentHover = self;
			end
		else
			currentHover = nil;
		end
	else
		currentHover = nil;
	end
	if (module:getOption("hideTooltip")) then
		-- Before hiding the tooltip, set the tooltip to a character
		-- to ensure the tooltip gets shown. This will ensure that the
		-- GameTooltip's OnHide script will get executed when we hide
		-- the tooltip.
		GameTooltip:SetText(" ");
		GameTooltip:Hide();
	end
end

local function actionbuttonOnEnter(self, ...)
	updateHover(nil, self);
	module:schedule(1, true, updateHover);
	module.groupOnEnter(self.object);
	self.object:onenter(self, ...);
end
			
local function actionbuttonOnLeave(self, ...)
	-- Before hiding the tooltip, assign some text to it to ensure that the
	-- tooltip gets shown. We need to do this because we won't have shown a
	-- a tooltip if there was no action associated with the button.
	-- We need to make sure the GameTooltip's OnHide script executes so that
	-- it will reset things like the GameTooltip.default value.
	GameTooltip:SetText(" ");
	GameTooltip:Hide();
	currentHover = nil;
	module:unschedule(updateHover, true);
	module.groupOnLeave(self.object);
	self.object:onleave(self, ...);
end

local function actionbuttonOnDragStart(self, ...)
	self.object:ondragstart(self, ...);
end

local function actionbuttonOnDragStop(self, ...)
	self.object:ondragstop(self, ...);
end
			
local function actionbuttonOnReceiveDrag(self, ...)
	self.object:onreceivedrag(self, ...);
end

local function actionbuttonOnMouseDown(self, ...)
	self.object:onmousedown(self, ...);
end
			
local function actionbuttonOnMouseUp(self, ...)
	self.object:onmouseup(self, ...);
end
			
local function actionbuttonPreClick(self, ...)
	self.object:preclick(self, ...);
end

local function actionbuttonPostClick(self, ...)
	self.object:postclick(self, ...);
end

local actionButtonObjectPool = { };

local function getActionButton(buttonId)
	local button, parent;
	button = tremove(actionButtonObjectPool);
	if (not button) then
		button = CreateFrame("CheckButton", "CT_BarModActionButton" .. buttonId, nil, "SecureActionButtonTemplate,SecureHandlerBaseTemplate");
		button:SetHeight(36);
		button:SetWidth(36);
		button:SetPoint("TOPLEFT", 0, 0);

		parent = button;

		button.backdrop = parent:CreateTexture();
		button.icon = parent:CreateTexture();
		button.border = parent:CreateTexture();
		button.flash = parent:CreateTexture();

		button.normalTexture = parent:CreateTexture();
		button.pushedTexture = parent:CreateTexture();
		button.checkedTexture = parent:CreateTexture();
		button.highlightTexture = parent:CreateTexture();

		button.hotkey = parent:CreateFontString();
		button.count = parent:CreateFontString();
		button.name = parent:CreateFontString();

		button.cooldown = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate");
		button.cooldown:SetDrawEdge(false);
		button.cooldown:SetDrawBling(false);
		
		button.blingcontainer = CreateFrame("Frame", nil, button)
		button.blingcontainer:SetAllPoints()
		button.blingcontainer:SetClipsChildren(true)
		
		local bling = button.blingcontainer:CreateTexture(nil, "OVERLAY")
		bling:SetTexture("Interface\\Cooldown\\star4")
		bling:SetAllPoints()
		bling:SetVertexColor(0.3, 0.6, 1, 0)
		bling:SetBlendMode("ADD")
		button.bling = bling
		bling.ag = bling:CreateAnimationGroup()
		bling.r = bling.ag:CreateAnimation("Rotation")
		bling.r:SetDegrees(-45)
		bling.r:SetDuration(1.0)
		bling.a1 = bling.ag:CreateAnimation("Alpha")
		bling.a1:SetDuration(0.5)
		bling.a1:SetFromAlpha(0.0)
		bling.a1:SetToAlpha(0.6)
		bling.a2 = bling.ag:CreateAnimation("Alpha")
		bling.a2:SetDuration(0.5)
		bling.a2:SetStartDelay(0.5)
		bling.a2:SetFromAlpha(0.6)
		bling.a2:SetToAlpha(0.0)
		
		-- scale
		bling.s1 = bling.ag:CreateAnimation("Scale")
		bling.s1:SetDuration(0.4)
		bling.s2 = bling.ag:CreateAnimation("Scale")
		bling.s2:SetDuration(0.4)
		bling.s2:SetStartDelay(0.4)
		bling.s3 = bling.ag:CreateAnimation("Scale")
		bling.s3:SetDuration(0.2)
		bling.s3:SetStartDelay(0.8)
		
		do
			local toFunc = bling.s1.SetFromScale or bling.s1.SetScaleFrom
			local fromFunc = bling.s1.SetToScale or bling.s1.SetScaleTo
			
			fromFunc(bling.s1, 1.0, 1.0)
			toFunc (bling.s1, 1.8, 1.8)
			
			fromFunc(bling.s2, 1.0, 1.0)
			toFunc(bling.s2, 0.75, 0.75)
			
			fromFunc(bling.s3, 1.0, 1.0)
			toFunc(bling.s3, 1.2, 1.2)
		end
		
		module:regEvent("PLAYER_LOGIN", function()
			-- Delay these hooks for compatibility with OmniCC.
		
			button.cooldown:HookScript("OnCooldownDone", function(self) 
				bling.ag:Restart()
				bling.ag:Play()
			end)

			hooksecurefunc(button.cooldown, "SetCooldown", function(self, start, duration)
				bling.ag:Stop()
			end)
		end)
		
		button.recharge = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate");
		button.recharge:SetDrawSwipe(false);
		button.recharge:SetDrawBling(false);
		button.recharge:SetHideCountdownNumbers(true);
		
		button.FlyoutArrow = parent:CreateTexture()
		button.FlyoutArrow:SetSize(23, 11)
		button.FlyoutArrow:SetDrawLayer("ARTWORK", 2)
		button.FlyoutArrow:SetTexture("Interface\\Buttons\ActionBarFlyoutButton")
		button.FlyoutArrow:SetTexCoord("0.62500000", "0.98437500", "0.74218750", "0.82812500")
		
		button.FlyoutBorder = parent:CreateTexture()
		button.FlyoutBorder:SetSize(42,42)
		button.FlyoutBorder:SetPoint("CENTER")
		button.FlyoutBorder:SetDrawLayer("ARTWORK", 2)
		button.FlyoutBorder:SetTexture("Interface\\Buttons\ActionBarFlyoutButton")
		button.FlyoutBorder:SetTexCoord("0.01562500", "0.67187500", "0.39843750", "0.72656250")

		button.FlyoutBorderShadow = parent:CreateTexture()
		button.FlyoutBorderShadow:SetSize(48,48)
		button.FlyoutBorderShadow:SetPoint("CENTER")
		button.FlyoutBorderShadow:SetDrawLayer("ARTWORK", 2)
		button.FlyoutBorderShadow:SetTexture("Interface\\Buttons\ActionBarFlyoutButton")
		button.FlyoutBorderShadow:SetTexCoord("0.01562500", "0.76562500", "0.00781250", "0.38281250")
		
		if CT_BarMod_SpellFlyout then
			-- WoW 10.x
			button.FlyoutArrowContainer = CreateFrame("Frame", nil, button)
			button.FlyoutArrowContainer:SetAllPoints()
			
			button.FlyoutArrowContainer.FlyoutArrowNormal = button.FlyoutArrowContainer:CreateTexture(nil, "ARTWORK", nil, 2)
			button.FlyoutArrowContainer.FlyoutArrowNormal:SetAtlas("UI-HUD-ActionBar-Flyout")
			button.FlyoutArrowContainer.FlyoutArrowNormal:Hide()
			button.FlyoutArrowContainer.FlyoutArrowNormal:SetSize(18,7)
			button.FlyoutArrowContainer.FlyoutArrowNormal:SetPoint("TOP")

			button.FlyoutArrowContainer.FlyoutArrowPushed = button.FlyoutArrowContainer:CreateTexture(nil, "ARTWORK", nil, 2)
			button.FlyoutArrowContainer.FlyoutArrowPushed:SetAtlas("UI-HUD-ActionBar-Flyout-Down")
			button.FlyoutArrowContainer.FlyoutArrowPushed:Hide()
			button.FlyoutArrowContainer.FlyoutArrowPushed:SetSize(18,8)	--sic? (WoW 10.0.2)
			button.FlyoutArrowContainer.FlyoutArrowPushed:SetPoint("TOP")

			button.FlyoutArrowContainer.FlyoutArrowHighlight = button.FlyoutArrowContainer:CreateTexture(nil, "ARTWORK", nil, 2)
			button.FlyoutArrowContainer.FlyoutArrowHighlight:SetAtlas("UI-HUD-ActionBar-Flyout-Mouseover")
			button.FlyoutArrowContainer.FlyoutArrowHighlight:Hide()
			button.FlyoutArrowContainer.FlyoutArrowHighlight:SetSize(18,7)
			button.FlyoutArrowContainer.FlyoutArrowHighlight:SetPoint("TOP")
			
			SecureHandlerSetFrameRef(button, "ctSpellFlyout", CT_BarMod_SpellFlyout)
			SecureHandlerWrapScript(button, "OnClick", button, [=[
				local type, action = GetActionInfo(self:GetAttribute("action"))
				if type == "flyout" then
					local spellFlyout = owner:GetFrameRef("ctSpellFlyout")
					spellFlyout:SetAttribute("newParent", self)
					spellFlyout:SetAttribute("newFlyoutID", action)
					spellFlyout:RunAttribute("toggleFlyout")
					return false
				end
			]=], nil)
		end

		button:SetNormalTexture(button.normalTexture);
		button:SetPushedTexture(button.pushedTexture);
		button:SetHighlightTexture(button.highlightTexture);
		button:SetCheckedTexture(button.checkedTexture);

		-- Save :SetPoint because Masque will replace it (for at least the hotkey) with a do-nothing function.
		-- We need the original SetPoint so we can reposition the fontstring if we need to disable Masque support
		-- after it has been enabled.
		button.hotkey.__CTBM__SetPoint = button.hotkey.SetPoint;
		button.count.__CTBM__SetPoint = button.count.SetPoint;
		button.name.__CTBM__SetPoint = button.name.SetPoint;

		-- Save :SetNormalTexture because Masque will hook it.
		-- We need to be able to call the method directly in order to prevent
		-- the hook from being called (when we're not using Masque to skin the buttons).
		button.__CTBM__SetNormalTexture = button.SetNormalTexture;

		-- Masque hooks the :SetFrameLevel of the button, so save a copy
		-- of the original in case we need it. At the moment, their hook
		-- isn't causing any issues for us, other than when they change
		-- the level of the cooldown (which we change when using a CT skin).
		button.__CTBM__SetFrameLevel = button.SetFrameLevel;

		button:SetScript("OnEnter", actionbuttonOnEnter);
		button:SetScript("OnLeave", actionbuttonOnLeave);
		button:SetScript("OnDragStart", actionbuttonOnDragStart);
		button:SetScript("OnDragStop", actionbuttonOnDragStop);
		button:SetScript("OnReceiveDrag", actionbuttonOnReceiveDrag);
		button:SetScript("OnMouseDown", actionbuttonOnMouseDown);
		button:SetScript("OnMouseUp", actionbuttonOnMouseUp);
		button:SetScript("PreClick", actionbuttonPreClick);
		button:SetScript("PostClick", actionbuttonPostClick);
	end
	return button;
end

local function getActionButtonId()
	local num = #actionButtonList;
	for buttonId = 1, num, 1 do
		if ( not actionButtonList[buttonId] ) then
			return buttonId;
		end
	end
	return num + 1;
end

--------------------------------------------
-- Action Button Class

module.actionButtonClass = actionButton;

-- Create a new object
function actionButton:new(...)
	local button = { };
	setmetatable(button, newButtonMeta);
	button:constructor(...);
	return button;
end

-- Destroy an object
function actionButton:drop()
	self:destructor();
end

-- Constructor, run on object creation
function actionButton:constructor(buttonId, actionId, groupId, count, noInherit, resetMovable)

	if ( noInherit ) then
		return;
	end

	buttonId = buttonId or getActionButtonId();
	actionId = min(CT_BarMod_SecureFrame:GetAttribute("maxAction"), max(1, actionId or buttonId));

	local button = getActionButton(buttonId);
--	local obj = savedButtons[buttonId];
	
	if ( resetMovable ) then
		module:resetMovable(buttonId);
		self.scale = UIParent:GetScale();
	else
		self.scale = button:GetScale();
	end
	
	self.groupId = groupId or ceil(buttonId / 12);

	self.actionId = actionId;
	self.buttonId = buttonId;
	self.buttonNum = count;
	self.showButton = true;
	self.gridShow = 0;

	module:registerMovable(buttonId, button);
	actionButtonList[buttonId] = self;

	button.object = self;
	button.cooldown.object = self;
	button.recharge.object = self;
	button.action = actionId; -- For use by ActionButton_UpdateFlyout()
	button.ctbarmod = true;  -- Our button.

	button:SetAttribute("gridevent", 0);
	button:SetAttribute("flyoutDirection", module:getOption("flyoutDirection" .. self.buttonId) or "UP");

	self.button = button;
	self.name = button:GetName();

	self:setSkin(1); -- 1==CT_BarMod standard skin
	self:reskin();

	self:savePosition();
	self:setMode(currentMode);
	self:setBinding();

	--self:setClickDirection( not not module:getOption("clickDirection"), not not module:getOption("clickIncluded") );
	self:setClickDirection(
		GetCVar("ActionButtonUseKeyDown") == "1",		-- "1" is the default value, meaning activate abilities when you press DOWN
		module:getOption("onMouseDown")				-- this will be ignored if the CVar is disabled
	);		
	
	button:RegisterForDrag("LeftButton", "RightButton");
	button:SetAttribute("type", "action");
end

-- Destructor, run on object destruction
function actionButton:destructor(noInherit)

	if ( noInherit ) then
		return;
	end
	
	self.button:Hide();
	actionButtonList[self.buttonId] = nil;
	
	tinsert(self, actionButtonObjectPool);
end

-- General updater
function actionButton:update()
	-- Placeholder for derived classes
end

-- Update texture
function actionButton:updateTexture()
	self.button.icon:SetTexture(GetActionTexture(self.actionId));
end

-- Updates the options table for this button, or creates it
function actionButton:updateOptions()
	local buttonId = self.buttonId;
	local option = module:getOption(buttonId);
	if ( option ) then
		-- Update table
	else
		-- Create new table
	end
end

-- Sets the editing mode
function actionButton:setMode(newMode)
	self:destructor(true);
	setmetatable(self, newButtonMeta);
	self:constructor(nil, nil, nil, nil, true);
	self:update();
end

-- Set if action is triggered on click up or click down.
-- This affects the mouse for ALL bars, and also the keybind for extra bars (7-10).
-- Keybinds for bars 2-6 and the action bar are handled elsewhere in a way that is integrated with console variable "ActionButtonUseKeyDown"
--
-- Update: Keybinds trigger Button31, but are now converted to LeftButton during execution so the macro conditional [button:1] will trigger.
function actionButton:setClickDirection(onKeyDown, alsoOnMouseDown)

	if module:getGameVersion() >= 10 then
		alsoOnMouseDown = true
	end
	
	self.button:SetAttribute("type31", "")
	if (self.onClickDirectionPreviouslySet) then
		self.button:UnwrapScript(self.button, "OnClick")
	end
	self.onClickDirectionPreviouslySet = true
	if (onKeyDown and alsoOnMouseDown) then
		self.button:RegisterForClicks("AnyDown");
		self.button:WrapScript(
			self.button,
			"OnClick",
			--pre-body
			[=[
				-- self, button, down
				if (button == "Button31") then
					return "LeftButton"
				end
			]=]
		)
	elseif (onKeyDown) then
		self.button:RegisterForClicks("AnyUp", "Button31Down")
		self.button:WrapScript(
			self.button, 
			"OnClick", 
			--pre-body
			[=[
				--self, button, down
				if (button == "Button31" and down) then
					return "LeftButton"
				end
			]=]
		)
	else
		self.button:RegisterForClicks("AnyUp")
		self.button:WrapScript(
			self.button,
			"OnClick",
			--pre-body
			[=[
				-- self, button, down
				if (button == "Button31") then
					return "LeftButton"
				end
			]=]
		)
	end		
end


-- Change a button's scale
function actionButton:setScale(scale)
	scale = min(max(scale, 0.35), 3);
	self:savePosition();
	self.scale = scale;
	self:updatePosition();
	
	if ( not self.moving ) then
		module:stopMovable(self.buttonId);
	end
end

-- Start moving this button
function actionButton:move()
	self.moving = true;
	module:moveMovable(self.buttonId);
end

-- Stop moving this button
function actionButton:stopMove()
	self.moving = nil;
	module:stopMovable(self.buttonId);
	self:savePosition();
end

-- Save position for this session
function actionButton:savePosition()
	local scale, xPos, yPos = self.scale, self.button:GetCenter();
	self.xPos, self.yPos = xPos * scale, yPos * scale;
	self:updatePosition();
end

-- Update position, takes scale into account
function actionButton:updatePosition()
	local scale, xPos, yPos = self.scale, self.xPos, self.yPos;
	local button = self.button;

	if (button:IsProtected() and InCombatLockdown()) then
		return;
	end
	button:SetScale(scale);
	button:ClearAllPoints();
	if (scale == 0) then
		xPos = 0;
		yPos = 0;
	else
		xPos = xPos / scale;
		yPos = yPos / scale;
	end
	button:SetPoint("CENTER", nil, "BOTTOMLEFT", xPos, yPos);
end

-- Set binding depending on saved option
function actionButton:setBinding(binding, delete)
	-- binding = binding or module:getOption("BINDING-" .. self.buttonId);
	if ( binding and not InCombatLockdown()) then
		if (delete) then
			SetBinding(binding, nil);
		else
			SetBindingClick(binding, self.name, "Button31");
		end
	end
	self:updateBinding();
end

-- Fallback Placeholders
function actionButton:updateBinding() end
function actionButton:ondragstart() end
function actionButton:ondragstop() end
function actionButton:onreceivedrag() end
function actionButton:onmousedown() end
function actionButton:onmouseup() end
function actionButton:postclick() end

--------------------------------------------
-- Action Button List Handler

local lastMethod;
module.actionButtonList = actionButtonList;

local function doMethod(__, ...)
	for buttonId, object in pairs(actionButtonList) do
		object[lastMethod](object, ...);
	end
end
setmetatable(actionButtonList, { __index =
	function(key, value)
		local obj = currentButtonClass[value];
		if ( type(obj) == "function" ) then
			lastMethod = value;
			return doMethod;
		else
			return obj;
		end
	end
});

--------------------------------------------
-- Event Handlers

module:regEvent("ACTIONBAR_SLOT_CHANGED", function(event, actionId)
	if (actionId == 0) then
		actionButtonList:update();
	else
		-- local object = actionButtonList[id];
		for buttonId, object in pairs(actionButtonList) do
			if (object and object.actionId == actionId)  then
				object:update();
			end
		end
	end
end);



module:regEvent("SPELL_UPDATE_ICON", function()
	actionButtonList:updateTexture();
end);

--------------------------------------------
-- Mode Handler

function module:setMode(newMode)
	if ( currentMode ~= newMode ) then
		if ( currentMode ) then
			module[currentMode.."Disable"](module);
		end
		newButtonMeta = module[newMode.."ButtonMeta"];
		currentButtonClass = module[newMode.."ButtonClass"];
		actionButtonList:setMode(newMode);
		currentMode = newMode;
		module[newMode.."Enable"](module);
	end
end

--------------------------------------------
-- Group id/number conversion.

-- num == Index into the groupList table.
-- id  == Unique number assigned to the group.
--        This number is used in option and frame names.
--        It is independent of the bar's position in the groupList table.
-- Bar == Name of group.
--        This is what gets displayed on screen.

-- Bar   1 = id  10 = num  1 (page  1)
-- Bar   2 = id   1 = num  2 (page  2)
-- Bar   3 = id   2 = num  3 (page  3)
-- Bar   4 = id   3 = num  4 (page  4)
-- Bar   5 = id   4 = num  5 (page  5)
-- Bar   6 = id   5 = num  6 (page  6)
-- Bar   7 = id   6 = num  7 (page  7)
-- Bar   8 = id   7 = num  8 (page  8)
-- Bar   9 = id   8 = num  9 (page  9)
-- Bar  10 = id   9 = num 10 (page 10)
-- Bar  11 = id  11 = num 11 (various) (control bar) (shows vehicle, possess, override)
-- Bar  12 = id  12 = num 12 (various) (action bar) (shows 1 to 10, vehicle, possess, override)

-- Originally there were 9 bars.
-- - Bar 1 was action ids 13 to 24.
-- - Bar 1 was stored at index 1 of the groupList table.
-- - Bar 2 was action ids 25 to 36.
-- - Bar 2 was stored at index 2 of the groupList table.
-- - Bars 3 through 9 were action ids 37 to 120.
-- - Bars 3 through 9 were stored at index 3 through 9 of the groupList table.
--
-- Later a 10th bar was added which used action ids 1 to 12.
-- - Bar 1 through Bar 9 were renamed Bar 2 through Bar 10.
-- - The new bar was named Bar 1.
-- - Saved options for all bar are stored in a table using a key
--   that consists of an option name and a number. Originally that
--   number was the index used to access the groupList table.
-- - When the new 10th bar was inserted at position 1 in the groupList
--   table, it caused the position of the other bars in the table
--   to shift by 1. This meant that the bar's position in the
--   groupList table could no longer be used to access the saved
--   option.
-- - To allow access to the correct saved option, an id number
--   was assigned to each group. The id number used was equal
--   to the bar's original position in the groupList table.
-- - The new bar which is now in position 1 of the groupList table
--   was assigned id number 10.
--
-- Later an 11th bar was added which used action ids 121 to 132.
-- - The new bar was assigned id number 11.
--
-- Later a 12th bar was added which used variable action id numbers.
-- - The new bar was assigned id number 12.
--
-- In WoW 5.0:
-- - Blizzard got rid of the bonus action bar and are now using 
--   an override bar to show both the vehicle actions and some
--   which used to be on the bonus action bar.
-- - Multicast action numbers (formerly used by the totem bar) are now 121 to 132.
-- - The vehicle action numbers are now 133 to 144.
-- - There are TempShapeshiftBar action numbers from 145 to 156.
-- - The override action numbers are 157 to 168.
-- - In version 5 of CT_BarMod:
--   - Our control bar (bar 11) will show the vehicle and override actions
--     just like it did in version 4, and now it also shows possess actions.
--   - Our action bar (bar 12) will show bar 1 to 10 actions, vehicle actions,
--     override actions, and possess actions just like it did in version 4.
--   - At the moment I'm not sure when the TempShapeshiftBar actions are used.

module.GroupNumToId = function(groupNum)
	-- Convert group number to group id.
	-- Group numbers are temporary values that do not persist beyond the current game session.
	local groupId;
	if (groupNum == 1) then
		-- Id 10 == Num 1.
		groupId = 10;
	else
		if (groupNum <= 10) then
			-- Id 1 to 9 = Num 2 to 10.
			groupId = groupNum - 1;

		else
			-- Id 11 to 12 == Num 11 to 12.
			groupId = groupNum;
		end
	end
	return groupId;
end

module.GroupIdToNum = function(groupId)
	-- Convert group id to group number.
	-- Group id numbers are persistant values that exist beyond the current game session.
	local groupNum;
	if (groupId == 10) then
		-- Num 1 == Id 10.
		groupNum = 1;
	else
		if (groupId <= 9) then
			-- Num 2 to 10 == Id 1 to 9.
			groupNum = groupId + 1;

		else
			-- Num 11 to 12 == Id 11 to 12.
			groupNum = groupId;
		end
	end
	return groupNum;
end
