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

--------------------------------------------
-- Initialization

local module = select(2,...);

local MODULE_NAME = "CT_UnitFrames";
local MODULE_VERSION = strmatch(C_AddOns.GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

CT_Library:registerModule(module);
--_G[MODULE_NAME] = module.publicInterface;	-- not ready for this until the options menu is reformatted to lua and integrated with the rest of CT Mod
_G[MODULE_NAME] = module;

--------------------------------------------
-- Initialization

do
	CreateFont("CT_UnitFrames_TextStatusBarText")
	CT_UnitFrames_TextStatusBarText:CopyFontObject(TextStatusBarText)
	CreateFont("CT_UnitFrames_PartyStatusBarText")
	CT_UnitFrames_PartyStatusBarText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
	CreateFont("CT_UnitFrames_PetStatusBarText")
	CT_UnitFrames_PetStatusBarText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
	module:regEvent("PLAYER_LOGIN", function()
		if (CT_UnitFramesOptions.makeFontLikeRetail) then
			CT_UnitFrames_TextStatusBarText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
		end
		if (CT_UnitFramesOptions.partyTextSize) then
			CT_UnitFrames_PartyStatusBarText:SetFont("Fonts\\FRIZQT__.TTF", 6 + CT_UnitFramesOptions.partyTextSize, "OUTLINE")
		end
		if (CT_UnitFramesOptions.petTextSize) then
			CT_UnitFrames_PetStatusBarText:SetFont("Fonts\\FRIZQT__.TTF", 6 + CT_UnitFramesOptions.petTextSize, "OUTLINE")
		end
	end)
	
end

--------------------------------------------
-- Frame dragging

function CT_UnitFrames_LinkFrameDrag(frame, drag, point, relative, x, y)
	frame:ClearAllPoints();
	frame:SetPoint(point, drag:GetName(), relative, x, y);
end

function CT_UnitFrames_ResetPosition(name)
	-- Reset the position of a movable frame (name == nil == all movable frames).
	if (InCombatLockdown()) then
		return;
	end
	local yoffset = 0;
	if (TitanMovable_GetPanelYOffset and TITAN_PANEL_PLACE_TOP and TitanPanelGetVar) then
		yoffset = yoffset + (tonumber( TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_TOP, TitanPanelGetVar("BothBars")) ) or 0);
	end
	if (not name or name == "CT_AssistFrame_Drag") then
		CT_AssistFrame_Drag:ClearAllPoints();
		CT_AssistFrame_Drag:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, -25 + yoffset);
		CT_AssistFrame_Drag:SetUserPlaced(true);
	end
	if (not name or name == "CT_FocusFrame_Drag") then
		CT_FocusFrame_Drag:ClearAllPoints();
		CT_FocusFrame_Drag:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, -180 + yoffset);
		CT_FocusFrame_Drag:SetUserPlaced(true);
	end
end

function CT_UnitFrames_ResetDragLink(name)
	-- Reset the link between a drag frame and its companion frame (name == nil == all movable frames).
	if (InCombatLockdown()) then
		return;
	end
	if (not name or name == "CT_AssistFrame_Drag") then
		CT_UnitFrames_LinkFrameDrag(CT_AssistFrame, CT_AssistFrame_Drag, "TOPLEFT", "TOPLEFT", -15, 21);
	end
	if (not name or name == "CT_FocusFrame_Drag") then
		CT_UnitFrames_LinkFrameDrag(CT_FocusFrame, CT_FocusFrame_Drag, "TOPLEFT", "TOPLEFT", -15, 21);
	end
end

--------------------------------------------
-- Health and mana bar text

local percentPattern = "%d%%";
local valuesPattern = "%s/%s";
local prefixedPercentPattern = "%s " .. percentPattern;
local prefixedValuesPattern = "%s " .. valuesPattern;

-- Midnight can expose unit health/power as restricted "secret numbers" that insecure code cannot
-- compare or do arithmetic with. ctSafeNumber returns the value when it is a normal, comparable
-- number, or nil when it is missing or restricted -- callers then skip that update instead of
-- crashing with "attempt to compare secret number value".
local ctSafeNumber = CT_Library.safeValue;	-- shared secret-value sanitizer (see CT_Library.lua); returns nil when restricted

function module:UpdateStatusBarTextString(textStatusBar, settings, lockShow)
	-- STEP 1: Avoid taint by creating creating a custom FontString called ctTextString
	-- STEP 2: Set the text as desired

	-- STEP 1:
	local textString =  textStatusBar.ctTextString;			
	if (not textString) then
		-- create our string
		local intermediateFrame = CreateFrame("Frame", nil, textStatusBar);	-- +1 frameLevel
		intermediateFrame:SetAllPoints();
		intermediateFrame = CreateFrame("Frame", nil, intermediateFrame);	-- +2 frameLevel
		intermediateFrame:SetAllPoints();
		intermediateFrame = CreateFrame("Frame", nil, intermediateFrame);	-- +3 frameLevel
		intermediateFrame:SetAllPoints();
		textString = intermediateFrame:CreateFontString(nil, "OVERLAY");
		textString:SetFontObject(textStatusBar.ctFont or CT_UnitFrames_TextStatusBarText);
		if (UnitFramesImproved) then
			textString:SetPoint("CENTER", textStatusBar, "BOTTOM", 0, textStatusBar:GetHeight()/2 + (textStatusBar.ctOffset or 0));
		else
			textString:SetPoint("CENTER", textStatusBar, 0, textStatusBar.ctOffset or 0);
		end
		textStatusBar.ctTextString = textString;
		
		-- prevent the default text string from ever appearing
		if (textStatusBar.TextString) then
			textStatusBar.TextString:SetAlpha(0);
		end
	end
	
	-- STEP 2:
	if (lockShow == nil) then lockShow = textStatusBar.lockShow; end
	local value = ctSafeNumber(textStatusBar:GetValue());
	local valueMin, valueMax = textStatusBar:GetMinMaxValues();
	valueMax = ctSafeNumber(valueMax);
	if ( value and valueMax and valueMax > 0  and not ( textStatusBar.pauseUpdates ) ) then
		local style = settings[1];
		local abbreviate = CT_UnitFramesOptions.largeAbbreviate ~= false;
		local breakup = CT_UnitFramesOptions.largeBreakUp ~= false;
		local prefix;
		if (lockShow > 0) then
			style = 4;
			prefix = 1;
		end
		--textStatusBar:Show();		-- causing errors in 10.1.7 along with similar calls at lines 159 and 210
		if ( value == 0 and textStatusBar.zeroText ) then
			textString:SetText(textStatusBar.zeroText);
			textStatusBar.isZero = 1;			
		elseif ( style == 2 ) then
			textStatusBar.isZero = nil;
			-- Percent
			if ( textStatusBar.prefix and prefix ) then
				textString:SetText(prefixedPercentPattern:format(value / valueMax * 100));
			else
				textString:SetText(percentPattern:format(value / valueMax * 100));
			end
		elseif (style == 1) then
			-- None
			textString:SetText("");
			textStatusBar.isZero = nil;
			--textStatusBar:Show();
		elseif (style == 3) then
			-- Deficit
			textStatusBar.isZero = nil;
			value = value - valueMax;
			if (value >= 0) then
				textString:SetText("");
			elseif (abbreviate) then
				if ( textStatusBar.prefix and prefix ) then
					textString:SetText(textStatusBar.prefix .. " " .. module:abbreviateLargeNumbers(value, breakup));
				else
					textString:SetText(module:abbreviateLargeNumbers(value, breakup));
				end
			elseif ( textStatusBar.prefix and prefix ) then
				textString:SetText(textStatusBar.prefix .. " " .. module:breakUpLargeNumbers(value, breakup));
			else
				textString:SetText(module:breakUpLargeNumbers(value, breakup));
			end
		elseif (style == 5) then
			-- Current
			textStatusBar.isZero = nil;
			if (abbreviate) then
				if ( textStatusBar.prefix and prefix ) then
					textString:SetText(textStatusBar.prefix .. " " .. module:abbreviateLargeNumbers(value, breakup));
				else
					textString:SetText(module:abbreviateLargeNumbers(value, breakup));
				end
			elseif ( textStatusBar.prefix and prefix ) then
				textString:SetText(textStatusBar.prefix .. " " .. module:breakUpLargeNumbers(value, breakup));
			else
				textString:SetText(module:breakUpLargeNumbers(value, breakup));
			end
		else
			-- Values
			textStatusBar.isZero = nil;
			if (abbreviate) then
				value = module:abbreviateLargeNumbers(value, breakup);
				valueMax = module:abbreviateLargeNumbers(valueMax, breakup);
			elseif (breakup) then
				value = module:breakUpLargeNumbers(value, breakup);
				valueMax = module:breakUpLargeNumbers(valueMax, breakup);
			end
			if ( textStatusBar.prefix and prefix ) then
				textString:SetText(prefixedValuesPattern:format(textStatusBar.prefix, value, valueMax));
			else
				textString:SetText(valuesPattern:format(value, valueMax));
			end
		end
		textString:Show();
	else
		textString:Hide();
		--textStatusBar:Hide();
	end
	textString:SetTextColor(settings[2], settings[3], settings[4], settings[5]);
end

function module:UpdateBesideBarTextString(textStatusBar, settings, textString)
	if(textString) then
		local value = ctSafeNumber(textStatusBar:GetValue());
		local valueMin, valueMax = textStatusBar:GetMinMaxValues();
		valueMax = ctSafeNumber(valueMax);
		if ( value and valueMax and valueMax > 0 ) then
			local style = settings[1];
			local abbreviate = CT_UnitFramesOptions.largeAbbreviate ~= false;
			local breakup = CT_UnitFramesOptions.largeBreakUp;
			if ( style == 2 ) then
				-- Percent
				textString:SetText(percentPattern:format(value / valueMax * 100));
			elseif (style == 1) then
				-- None
				textString:SetText("");
			elseif (style == 3) then
				-- Deficit
				value = value - valueMax;
				if (value >= valueMax) then
					textString:SetText("");
				elseif (abbreviate) then
					textString:SetText(module:abbreviateLargeNumbers(value, breakup));
				else
					textString:SetText(module:breakUpLargeNumbers(value, breakup));
				end
			elseif (style == 5) then
				-- Current
				if (abbreviate) then
					textString:SetText(module:abbreviateLargeNumbers(value, breakup));
				else
					textString:SetText(module:breakUpLargeNumbers(value, breakup));
				end
			else
				-- Values
				if (abbreviate) then
					textString:SetText(valuesPattern:format(
						module:abbreviateLargeNumbers(value, breakup),
						module:abbreviateLargeNumbers(valueMax, breakup)
					));
				else
					textString:SetText(valuesPattern:format(
						module:breakUpLargeNumbers(value, breakup),
						module:breakUpLargeNumbers(valueMax, breakup)
					));
				end
			end
		else
			textString:SetText("");
		end
		textString:SetTextColor(settings[2], settings[3], settings[4], settings[5]);
	end
end

function CT_UnitFrames_HealthBar_OnValueChanged(self, value, smooth)
	if ( not value ) then
		return;
	end
	local r, g, b;
	local min, max = self:GetMinMaxValues();
	value, min, max = ctSafeNumber(value), ctSafeNumber(min), ctSafeNumber(max);
	if ( not (value and min and max) ) then
		return;
	end
	if ( (value < min) or (value > max) ) then
		return;
	end
	if ( (max - min) > 0 ) then
		value = (value - min) / (max - min);
	else
		value = 0;
	end
	if(smooth) then
		if(value > 0.5) then
			r = (1.0 - value) * 2;
			g = 1.0;
		else
			r = 1.0;
			g = value * 2;
		end
	else
		r = 0.0;
		g = 1.0;
	end
	b = 0.0;
	if ( not self.lockColor ) then
		self:SetStatusBarColor(r, g, b);
	end
end

function module:addClassicIncomingHeals(frame)
	if (UnitGetTotalAbsorbs or frame.myHealPredictionBar) then
		-- This should only fire on classic
		return
	end
	local myHealPredictionBar = frame.healthbar:CreateTexture(nil, "ARTWORK", "MyHealPredictionBarTemplate")
	myHealPredictionBar:Hide()
	local otherHealPredictionBar = frame.healthbar:CreateTexture(nil, "ARTWORK", "OtherHealPredictionBarTemplate")
	otherHealPredictionBar:Hide()
	frame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", frame.unit)
	local healthtexture = frame.healthbar:GetStatusBarTexture()
	frame:HookScript("OnEvent", function(__, event)
		if (event == "UNIT_HEAL_PREDICTION") then
			local health, maxHealth = frame.healthbar:GetValue(), select(2,frame.healthbar:GetMinMaxValues())
			if (maxHealth > 0) then
				local myHeals = C_CVar.GetCVar("predictedHealth") == "1" and (min(UnitGetIncomingHeals(frame.unit, "player") or 0, maxHealth - health)) or 0
				local otherHeals = C_CVar.GetCVar("predictedHealth") == "1" and (min(UnitGetIncomingHeals(frame.unit) or 0, maxHealth - health) - myHeals) or 0
				UnitFrameUtil_UpdateFillBar(frame, healthtexture, myHealPredictionBar, myHeals, 0)
				UnitFrameUtil_UpdateFillBar(frame, myHeals > 0 and myHealPredictionBar or healthtexture, otherHealPredictionBar, otherHeals, 0)
			end
		end
	end)
end