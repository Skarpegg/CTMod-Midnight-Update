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

--------------------------------------------
-- Mimicking SpellFlyout.xml

local spellFlyout

if SpellFlyoutMixin then
	-- WoW 11.1
	spellFlyout = CreateFrame("Frame", "CT_BarMod_SpellFlyout", nil, "SecureFrameTemplate, ResizeLayoutFrame, FlyoutPopupTemplate")
	Mixin(spellFlyout, SpellFlyoutMixin)
	spellFlyout:EnableMouse(true)
	spellFlyout:SetScript("OnShow", spellFlyout.OnShow)
	spellFlyout:SetScript("OnHide", spellFlyout.OnHide)
	spellFlyout:SetScript("OnEvent", spellFlyout.OnEvent)
	spellFlyout:OnLoad()
	
	spellFlyout.Toggle = nop -- replaced with secure snippet
	
	-- Workaround; pushing the buttons forward one frame level
	spellFlyout.buttonsFrame = CreateFrame("Frame", nil, spellFlyout)
	spellFlyout.buttonsFrame:SetAllPoints()

else
	-- Until WoW 11.0
	spellFlyout = CreateFrame("Frame", "CT_BarMod_SpellFlyout", nil, "SecureFrameTemplate, ResizeLayoutFrame")
	spellFlyout:SetToplevel(true)
	spellFlyout:Hide()
	spellFlyout:SetFrameStrata("DIALOG")
	spellFlyout:SetFrameLevel(10)
	spellFlyout:EnableMouse(true)
	spellFlyout.ignoreInlayout = true  -- sic

	spellFlyout.Background = CreateFrame("Frame", nil, spellFlyout)
	spellFlyout.Background:SetAllPoints()

	spellFlyout.Background.End = spellFlyout.Background:CreateTexture()
	spellFlyout.Background.End:SetAtlas("UI-HUD-ActionBar-IconFrame-FlyoutButton", true)

	spellFlyout.Background.HorizontalMiddle = spellFlyout.Background:CreateTexture()
	spellFlyout.Background.HorizontalMiddle:SetAtlas("_UI-HUD-ActionBar-IconFrame-FlyoutMidLeft", true)  -- sic

	spellFlyout.Background.VerticalMiddle = spellFlyout.Background:CreateTexture()
	spellFlyout.Background.VerticalMiddle:SetAtlas("!UI-HUD-ActionBar-IconFrame-FlyoutMid", true) -- sic

	spellFlyout.Background.Start = spellFlyout.Background:CreateTexture()
	spellFlyout.Background.Start:SetAtlas("UI-HUD-ActionBar-IconFrame-FlyoutBottom", true)

	spellFlyout:SetScript("OnShow", SpellFlyout_OnShow)
	spellFlyout:SetScript("OnHide", SpellFlyout_OnHide)

	spellFlyout:SetScript("OnEvent", function(self, event, ...)
		if (event == "SPELL_UPDATE_COOLDOWN") then
			local i = 1;
			local button = _G["CT_BarMod_SpellFlyoutButton"..i];
			while (button and button:IsShown()) do
				SpellFlyoutButton_UpdateCooldown(button);
				i = i+1;
				button = _G["CT_BarMod_SpellFlyoutButton"..i];
			end
		elseif (event == "CURRENT_SPELL_CAST_CHANGED") then
			local i = 1;
			local button = _G["CT_BarMod_SpellFlyoutButton"..i];
			while (button and button:IsShown()) do
				SpellFlyoutButton_UpdateState(button);
				i = i+1;
				button = _G["CT_BarMod_SpellFlyoutButton"..i];
			end
		elseif (event == "SPELL_UPDATE_USABLE") then
			local i = 1;
			local button = _G["CT_BarMod_SpellFlyoutButton"..i];
			while (button and button:IsShown()) do
				SpellFlyoutButton_UpdateUsable(button);
				i = i+1;
				button = _G["CT_BarMod_SpellFlyoutButton"..i];
			end
		elseif (event == "BAG_UPDATE") then
			local i = 1;
			local button = _G["CT_BarMod_SpellFlyoutButton"..i];
			while (button and button:IsShown()) do
				SpellFlyoutButton_UpdateCount(button);
				SpellFlyoutButton_UpdateUsable(button);
				i = i+1;
				button = _G["CT_BarMod_SpellFlyoutButton"..i];
			end
		elseif (event == "SPELL_FLYOUT_UPDATE") then
			local i = 1;
			local button = _G["CT_BarMod_SpellFlyoutButton"..i];
			while (button and button:IsShown()) do
				SpellFlyoutButton_UpdateCooldown(button);
				SpellFlyoutButton_UpdateState(button);
				SpellFlyoutButton_UpdateUsable(button);
				SpellFlyoutButton_UpdateCount(button);
				--SpellFlyoutButton_UpdateGlyphState(button);
				i = i+1;
				button = _G["CT_BarMod_SpellFlyoutButton"..i];
			end
		elseif (event == "PET_STABLE_UPDATE" or event == "PET_STABLE_SHOW") and not InCombatLockdown() then		-- InCombatLockdown() required because this is insecure
			self:Hide();  -- TODO: Find a way to securely do this during combat
		--elseif (event == "ACTIONBAR_PAGE_CHANGED") then
			--self:Hide();  -- Replaced with OnShow SecureHandler that creates a SecureStateDriver with "[nobar:##] hide;"
		end
	end)

	SpellFlyout_OnLoad(spellFlyout)
	spellFlyout:SetBorderColor(0.5, 0.5, 0.5)
	spellFlyout:SetBorderSize(47)
	spellFlyout.Toggle = nop	-- replaced with a secure snippet

	-- Workaround; pushing the buttons forward one frame level
	spellFlyout.buttonsFrame = CreateFrame("Frame", nil, spellFlyout)
	spellFlyout.buttonsFrame:SetAllPoints()
end

--------------------------------------------
-- Insecure Code

function spellFlyout:updateBackground(farPoint, nearPoint, isVert, capAngle, midAngle)
	self.Background.End:ClearAllPoints()
	self.Background.VerticalMiddle:ClearAllPoints()
	self.Background.HorizontalMiddle:ClearAllPoints()
	self.Background.Start:ClearAllPoints()
	
	self.Background.End:SetPoint(farPoint)
	SetClampedTextureRotation(self.Background.End, capAngle)
	SetClampedTextureRotation(self.Background.Start, capAngle)
	
	if isVert then
		self.Background.VerticalMiddle:SetPoint(farPoint, self.Background.End, nearPoint)
		self.Background.VerticalMiddle:SetPoint(nearPoint)
		self.Background.Start:SetPoint(farPoint, self.Background.VerticalMiddle, nearPoint)
		SetClampedTextureRotation(self.Background.VerticalMiddle, midAngle)
		self.Background.VerticalMiddle:Show()
		self.Background.HorizontalMiddle:Hide()
	else
		self.Background.HorizontalMiddle:SetPoint(farPoint, self.Background.End, nearPoint)
		self.Background.HorizontalMiddle:SetPoint(nearPoint)
		self.Background.Start:SetPoint(farPoint, self.Background.HorizontalMiddle, nearPoint)
		SetClampedTextureRotation(self.Background.HorizontalMiddle, midAngle)
		self.Background.HorizontalMiddle:Show()
		self.Background.VerticalMiddle:Hide()
	end
end


--------------------------------------------
-- Secure Code

spellFlyout:SetAttribute("createdButtons", 0)

function module.createSpellFlyoutButtons(numSlots)	-- must not be called during combat lockdown
	for i=spellFlyout:GetAttribute("createdButtons")+1, numSlots do
		local button
		
		if SpellFlyoutPopupButtonMixin then
			button = CreateFrame("CheckButton", "CT_BarMod_SpellFlyoutButton" .. i, spellFlyout.buttonsFrame, "SpellFlyoutPopupButtonTemplate,SecureActionButtonTemplate")
			button.popup = spellFlyout
		else
			button = CreateFrame("CheckButton", "CT_BarMod_SpellFlyoutButton" .. i, spellFlyout.buttonsFrame, "SecureActionButtonTemplate,SmallActionButtonTemplate")
			button:SetScript("OnEnter", SpellFlyoutButton_SetTooltip )
			button:SetScript("OnDragStart", SpellFlyoutButton_OnDrag)
			button:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
		
		button:RegisterForClicks("AnyUp", "AnyDown")
		SecureHandlerWrapScript(button, "PostClick", button, [=[ if down == false then self:GetParent():GetParent():Hide() end ]=], nil)

		SecureHandlerSetFrameRef(spellFlyout, "button"..i, button)
		button:SetAttribute("slot", i)
		button:SetAttribute("type", "spell")
		spellFlyout:SetAttribute("createdButtons", i)

		button.Icon = _G["CT_BarMod_SpellFlyoutButton"..i.."Icon"]

		function button:updateSpellID(spellID)
			button.spellID = spellID
			button.Icon:SetTexture((GetSpellTexture or C_Spell.GetSpellTexture)(spellID))
		end
	end
end

spellFlyout:SetAttribute("toggleFlyout", [=[
	local newParent, newFlyoutID = self:GetAttribute("newParent"), self:GetAttribute("newFlyoutID")
	if newParent and newFlyoutID then
		if self:IsShown() and newParent == self:GetParent() then
			self:Hide()
		else
			local numKnownSlots = newParent:GetAttribute("numKnownSlots")
			if numKnownSlots > 0 then
				local direction = newParent:GetAttribute("flyoutDirection") or "UP"
				local prevButton = newParent
				for i=1, numKnownSlots do
					local button = self:GetFrameRef("button"..i)
					local spellID = newParent:GetAttribute("spell"..i)
					button:SetAttribute("spell", spellID)
					button:CallMethod("updateSpellID", spellID)
					button:ClearAllPoints()
					if direction == "UP" then
						button:SetPoint("BOTTOM", prevButton, "TOP", 0, 4)
					elseif direction == "LEFT" then
						button:SetPoint("RIGHT", prevButton, "LEFT", -4, 0)
					elseif direction == "DOWN" then
						button:SetPoint("TOP", prevButton, "BOTTOM", 0, -4)
					elseif direction == "RIGHT" then
						button:SetPoint("LEFT", prevButton, "RIGHT", 4, 0)
					end
					button:Show()
					prevButton = button
				end
				self:SetParent(newParent)
				self:SetFrameStrata("DIALOG")
				self:ClearAllPoints()
				if direction == "UP" then
					self:SetPoint("BOTTOM", newParent, "TOP", 0, 3)
					self:SetWidth(47)
					self:SetHeight(numKnownSlots * 34 + 7)
					self:CallMethod("updateBackground", "TOP", "BOTTOM", true, 0, 0)
				elseif direction == "LEFT" then
					self:SetPoint("RIGHT", newParent, "LEFT", -3, 0)
					self:SetWidth(numKnownSlots * 34 + 7)
					self:SetHeight(47)
					self:CallMethod("updateBackground", "LEFT", "RIGHT", false, 270, 180)
				elseif direction == "DOWN" then
					self:SetPoint("TOP", newParent, "BOTTOM", 0, -3)
					self:SetWidth(47)
					self:SetHeight(numKnownSlots * 34 + 7)
					self:CallMethod("updateBackground", "BOTTOM", "TOP", true, 180, 180)
				elseif direction == "RIGHT" then
					self:SetPoint("LEFT", newParent, "RIGHT", 3, 0)
					self:SetWidth(numKnownSlots * 34 + 7)
					self:SetHeight(47)
					self:CallMethod("updateBackground", "RIGHT", "LEFT", false, 90, 0)
				end
				self:Show()
				for i=numKnownSlots+1, self:GetAttribute("createdButtons") do
					local button = self:GetFrameRef("button"..i)
					button:Hide()
					button:CallMethod("updateSpellID", 0)
				end
			else
				self:Hide()
			end
		end
	else
		self:Hide()
	end
]=])

function module.updateFlyout(self, isButtonDownOverride)
	if (not self.FlyoutArrowContainer or
		not self.FlyoutBorderShadow) then
		return;
	end
	local actionType = GetActionInfo(self.action);
	if (actionType ~= "flyout") then
		self.FlyoutBorderShadow:Hide();
		self.FlyoutArrowContainer:Hide();
		return;
	end
	-- Update border
	local isMouseOverButton =  self:IsMouseMotionFocus();
	local isFlyoutShown = SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == self;
	if (isFlyoutShown or isMouseOverButton) then
		self.FlyoutBorderShadow:Show();
	else
		self.FlyoutBorderShadow:Hide();
	end
	-- Update arrow
	local isButtonDown;
	if (isButtonDownOverride ~= nil) then
		isButtonDown = isButtonDownOverride;
	else
		isButtonDown = self:GetButtonState() == "PUSHED";
	end
	local flyoutArrowTexture = self.FlyoutArrowContainer.FlyoutArrowNormal;
	if (isButtonDown) then
		flyoutArrowTexture = self.FlyoutArrowContainer.FlyoutArrowPushed;
		self.FlyoutArrowContainer.FlyoutArrowNormal:Hide();
		self.FlyoutArrowContainer.FlyoutArrowHighlight:Hide();
	elseif (isMouseOverButton) then
		flyoutArrowTexture = self.FlyoutArrowContainer.FlyoutArrowHighlight;
		self.FlyoutArrowContainer.FlyoutArrowNormal:Hide();
		self.FlyoutArrowContainer.FlyoutArrowPushed:Hide();
	else
		self.FlyoutArrowContainer.FlyoutArrowHighlight:Hide();
		self.FlyoutArrowContainer.FlyoutArrowPushed:Hide();
	end
	self.FlyoutArrowContainer:Show();
	flyoutArrowTexture:Show();
	flyoutArrowTexture:ClearAllPoints();
	local arrowDirection = self:GetAttribute("flyoutDirection");
	local arrowDistance = isFlyoutShown and 1 or 4;
	
	--[[ START MODIFICATION CTMOD
	
	-- If you are on an action bar then base your direction based on the action bar's orientation
	local actionBar = self:GetParent();
	if (actionBar.actionButtons) then
		arrowDirection = actionBar:GetSpellFlyoutDirection();
	end
	
	END MODIFICATION --]]
	
	if (arrowDirection == "LEFT") then
		SetClampedTextureRotation(flyoutArrowTexture, isFlyoutShown and 90 or 270);
		flyoutArrowTexture:SetPoint("LEFT", self, "LEFT", -arrowDistance, 0);
	elseif (arrowDirection == "RIGHT") then
		SetClampedTextureRotation(flyoutArrowTexture, isFlyoutShown and 270 or 90);
		flyoutArrowTexture:SetPoint("RIGHT", self, "RIGHT", arrowDistance, 0);
	elseif (arrowDirection == "DOWN") then
		SetClampedTextureRotation(flyoutArrowTexture, isFlyoutShown and 0 or 180);
		flyoutArrowTexture:SetPoint("BOTTOM", self, "BOTTOM", 0, -arrowDistance);
	else
		SetClampedTextureRotation(flyoutArrowTexture, isFlyoutShown and 180 or 0);
		flyoutArrowTexture:SetPoint("TOP", self, "TOP", 0, arrowDistance);
	end
end

-- Hide the spell flyout when the action bar changes; secure alternative to SpellFlyout's event handler
SecureHandlerWrapScript(spellFlyout, "OnShow", spellFlyout, [=[	RegisterAttributeDriver(self, "state-visibility", "[nobar:" .. GetActionBarPage() .."]hide") ]=], nil)
SecureHandlerWrapScript(spellFlyout, "OnHide", spellFlyout, [=[ RegisterAttributeDriver(self, "state-visibility", "") ]=], nil)