------------------------------------------------
--               CT_UnitFrames                --
--                                            --
-- Heavily customizable mod that allows you   --
-- to modify the Blizzard unit frames into    --
-- your personal style and liking.            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local module = select(2, ...);

-- before/after WoW 10.x
local healthBar = TargetFrameHealthBar or TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar or TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar
local manaBar = TargetFrameManaBar or TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar

function CT_TargetFrameOnEvent(self, event, arg1, ...)

	if ( event == "PLAYER_LOGIN" ) then
		if (UnitFrame_UpdateThreatIndicator) then
			hooksecurefunc("UnitFrame_UpdateThreatIndicator", CT_TargetFrame_UpdateThreatIndicator)
		end
		CT_TargetFrame_SetClassPosition(true)
		if ( GetCVarBool("predictedPower") ) then
			local statusbar = TargetFrameManaBar
			statusbar:SetScript("OnUpdate", UnitFrameManaBar_OnUpdate)
			UnitFrameManaBar_UnregisterDefaultEvents(statusbar)
		end
	end
end

if TargetFrame_ResetUserPlacedPosition then
	-- prior to WoW 10.x, if the user reset the target frame's position then it was necessary to shift it slightly to the right.  (see PlayerFrame.xml)
	
	local function shiftTargetFrame()
		TargetFrame.ClearAllPoints()
		TargetFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 265, -4)
	end
	
	local function onResetUserPlacedPosition()
		module:afterCombat(shiftTargetFrame)
	end
	
	hooksecurefunc("TargetFrame_ResetUserPlacedPosition", onResetUserPlacedPosition)
end


-- Adapting code by github user shoestare, this function now performs two tasks:
--   STEP 1 (original): Displays the unit class or creature type in the target class frame
--   STEP 2 (new in 8.2.0.8): Changes the color of the target class frame to indicate friend, hostile, pvp, etc.
function CT_SetTargetClass()
	-- STEP 1:
	if ( CT_UnitFramesOptions.displayTargetClass and UnitExists("target") ) then
		if ( UnitIsPlayer("target") ) then
			CT_TargetFrameClassFrameText:SetText(UnitClass("target") or "");
		else
			CT_TargetFrameClassFrameText:SetText(UnitCreatureType("target") or "");
		end
	else
		CT_TargetFrameClassFrameText:SetText("");
		return;
	end

	-- STEP 2:
	local r, g, b = 0, 0, 0;
	if (UnitIsFriend("target", "player")) then
		if (UnitIsPlayer("target")) then
			-- set the overall shade
			if (UnitInParty("target") or UnitInRaid("target")) then
				g,b = 0.5, 0.5;
			elseif (UnitIsInMyGuild("target")) then
				g,b = 0.25, 0.25;
			end
			-- set the primary color
			if (UnitIsPVP("target")) then
				g = 1;
			else
				b = 1;
			end
		else
			-- friendly, but not a player
			b = 1;
		end
	elseif ( UnitIsEnemy("target", "player") or UnitIsPVP("target") or UnitIsPVPFreeForAll("target")) then
		r = 1;
	else
		if (UnitIsPlayer("target")) then
			-- non-hostile player of the other faction
			r, g = 0.75, 0.25
		else
			-- non-hostile mob
			r, g = 0.5, 0.5
		end
	end
	CT_TargetFrameClassFrame:SetBackdropColor(r, g, b, 0.5);
end

if TargetofTargetHealthCheck then
	-- prior to WoW 10.x
	hooksecurefunc("TargetofTargetHealthCheck", function()
		if ( not UnitIsPlayer("targettarget") ) then
			TargetFrameToTPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0)
		end
	end)
else
	-- WoW 10.x
	hooksecurefunc(TargetFrameToT, "HealthCheck", function()
		if ( not UnitIsPlayer("targettarget") ) then
			TargetFrameToT.Portrait:SetVertexColor(1.0, 1.0, 1.0, 1.0)	
		end
	end)
end

function CT_TargetFrame_UpdateThreatIndicator(indicator, numericIndicator, unit)
	if (numericIndicator and numericIndicator == TargetFrameNumericalThreat) then
		local center = true;
		if (numericIndicator:IsShown()) then
			if (CT_UnitFramesOptions and CT_UnitFramesOptions.displayTargetClass) then
				center = false;
			end
		end
		if (center) then
			-- Center class frame over unit name
			CT_TargetFrame_SetClassPosition(true);
			-- Center numeric threat indicator
			CT_TargetFrame_SetThreatPosition(true, numericIndicator);
		else
			-- Shift class frame to the right
			CT_TargetFrame_SetClassPosition(false);
			-- Shift numeric threat indicator to the left.
			CT_TargetFrame_SetThreatPosition(false, numericIndicator);
		end
	end
end

function CT_TargetFrame_SetClassPosition(center)
	local frame = CT_TargetFrameClassFrame
	frame:ClearAllPoints()

	local buffsOnTop = TargetFrame.buffsOnTop
	if (center or buffsOnTop) then
		-- Center the class over the unit name.
		if (buffsOnTop) then
			-- Center class below the unit frame
			local xoff
			if (TargetFrameToT and TargetFrameToT:IsShown()) then
				xoff = -13
			else
				xoff = 0
			end
			frame:SetPoint("TOP", TargetFrameTextureFrameName or TargetFrame.TargetFrameContent.TargetFrameContentMain.Name, "BOTTOM", xoff, TargetFrame.TargetFrameContent and -35 or -31);
		else
			if TargetFrame.TargetFrameContent then
				frame:SetPoint("BOTTOM", TargetFrame.TargetFrameContent.TargetFrameContentMain.Name, "TOP", 0, 2)
				frame:SetPoint("RIGHT", TargetFrame.TargetFrameContent.TargetFrameContentContextual.LeaderIcon, "LEFT")
			else
				frame:SetPoint("BOTTOM", TargetFrameTextureFrameName, "TOP", 0, 4)
			end
		end
		frame:SetWidth(100);
		CT_TargetFrameClassFrameText:SetWidth(96);
	else
		-- Leave room on the left to display threat indicator.
		frame:SetPoint("BOTTOMLEFT", TargetFrameTextureFrameName or TargetFrame.TargetFrameContent.TargetFrameContentMain.Name, "TOPLEFT", 35, 5);
		frame:SetWidth(86);
		CT_TargetFrameClassFrameText:SetWidth(82);
	end
end

function CT_TargetFrame_SetThreatPosition(center, numericIndicator)
	local frame = numericIndicator;
	frame:ClearAllPoints();
	if (center) then
		frame:SetPoint("BOTTOM", TargetFrame, "TOP", -50, -22);
	else
		frame:SetPoint("BOTTOMLEFT", TargetFrame, "TOPLEFT", 7, -22);
	end
end

local function CT_TargetFrame_HealthTextStatusBar_UpdateTextString(bar)
	if (CT_UnitFramesOptions) then
		local style;
		if (UnitIsFriend("target", "player")) then
			style = CT_UnitFramesOptions.styles[3][1];
		else
			style = CT_UnitFramesOptions.styles[3][5];
		end
		module:UpdateStatusBarTextString(bar, style, 0)
		CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
		module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[3][2], CT_TargetHealthLeft)	
	end
end

local function CT_TargetFrame_ManaTextStatusBar_UpdateTextString(bar)
	if (CT_UnitFramesOptions) then
		module:UpdateStatusBarTextString(bar, CT_UnitFramesOptions.styles[3][3], 0)
		module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[3][4], CT_TargetManaLeft)
	end
end

module:regEvent("PLAYER_LOGIN", function()
	
	healthBar:HookScript("OnEnter", CT_TargetFrame_HealthTextStatusBar_UpdateTextString);
	healthBar:HookScript("OnLeave", CT_TargetFrame_HealthTextStatusBar_UpdateTextString);
	healthBar:HookScript("OnValueChanged", CT_TargetFrame_HealthTextStatusBar_UpdateTextString);
	--healthBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	
	manaBar:HookScript("OnEnter", CT_TargetFrame_ManaTextStatusBar_UpdateTextString);
	manaBar:HookScript("OnLeave", CT_TargetFrame_ManaTextStatusBar_UpdateTextString);
	manaBar:HookScript("OnValueChanged", CT_TargetFrame_ManaTextStatusBar_UpdateTextString);
	--manaBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	
	-- incoming heals on classic
	if (UnitGetTotalAbsorbs == nil) then
		module:addClassicIncomingHeals(TargetFrame)
	end
end);

--[[	replaced by PLAYER_LOGIN event

	function CT_TargetFrame_ShowTextStatusBarText(bar)
		if (bar == TargetFrameHealthBar or bar == TargetFrameManaBar) then
			CT_TargetFrame_TextStatusBar_UpdateTextString(bar);
		end
	end


	function CT_TargetFrame_HideTextStatusBarText(bar)
		if (bar == TargetFrameHealthBar or bar == TargetFrameManaBar) then
			CT_TargetFrame_TextStatusBar_UpdateTextString(bar);
		end
	end

	hooksecurefunc("TextStatusBar_UpdateTextString", CT_TargetFrame_TextStatusBar_UpdateTextString);
	hooksecurefunc("ShowTextStatusBarText", CT_TargetFrame_ShowTextStatusBarText);
	hooksecurefunc("HideTextStatusBarText", CT_TargetFrame_HideTextStatusBarText);
--]]

function module:AnchorTargetFrameSideText()
	local fsTable = { "CT_TargetHealthLeft", "CT_TargetManaLeft" };
	for i, name in ipairs(fsTable) do
		local frame = _G[name];

--		<Anchor point="RIGHT" relativeTo="TargetFrame" relativePoint="TOPLEFT">
--		<AbsDimension x="4" y="-46"/>
		local xoff = (CT_UnitFramesOptions.targetTextSpacing or 0);
		local yoff = -(46 + (i-1)*11);
		local onRight = CT_UnitFramesOptions.targetTextRight;
		frame:ClearAllPoints();
		if (onRight) then
			frame:SetPoint("LEFT", TargetFrame, "TOPRIGHT", xoff, yoff);
		else
			xoff = xoff - 4;
			frame:SetPoint("RIGHT", TargetFrame, "TOPLEFT", -xoff, yoff);
		end

	end
end

function module:ShowTargetFrameBarText()
	-- Do NOT call Blizzard's UnitFrameHealthBar_Update / UnitFrameManaBar_Update here. Invoking them
	-- from this insecure (tainted) path makes Blizzard's own code fail to compare the now-restricted
	-- health maxValue ("attempt to compare secret number value ... tainted by CT_UnitFrames").
	-- This function only runs on options changes; the bars are kept current by Blizzard's own event
	-- handling, so we just need to refresh our custom text from their current values.
	CT_TargetFrame_HealthTextStatusBar_UpdateTextString(healthBar);
	CT_TargetFrame_ManaTextStatusBar_UpdateTextString(manaBar);
end