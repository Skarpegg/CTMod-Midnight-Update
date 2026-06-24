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
------------------------------------------------

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctAddon;
local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

local setpoint;
local setparent;

local defDivisions = 20;
local defBarWidth = EXP_DEFAULT_WIDTH or 1024;

local updateDefaultBar = false;
local divOffsetY = 0;
local totDivisions = 0;
local tempWidth;

---------------------------------------------
-- Misc

local function isBusy()
	return module:isBlizzardAnimating();
end

local function setDelayedUpdate(value)
	module:setDelayedUpdate(ctAddon, value);
end

-------------------------------------------
-- Exhaustion tick, Experience bar
--
-- The experience bar is a modified version of
-- Blizzard's experience bar from MainMenuBar.lua
-- and MainMenuBar.xml.
--
-- A modified exp bar was needed to avoid positioning
-- issues with the default exp bar when Blizzard animates
-- the default exp bar on/off the screen. Attempting
-- to move the exp bar, re-parent it, etc during the
-- animation can lead to various elements of the bar
-- being positioned incorrectly after the animation
-- ends.

local function CT_BottomBar_ExhaustionTick_OnEvent(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_XP_UPDATE" or event == "UPDATE_EXHAUSTION" or event == "PLAYER_LEVEL_UP") then
		local playerCurrXP = UnitXP("player");
		local playerMaxXP = UnitXPMax("player");

		local exhaustionThreshold = GetXPExhaustion();
		local exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier = GetRestState();
		if (exhaustionStateID and exhaustionStateID >= 3) then
			CT_BottomBar_ExhaustionTick:SetPoint("CENTER", "CT_BottomBar_MainMenuExpBar", "RIGHT", 0, 0);
		end

		if (not exhaustionThreshold) then
			CT_BottomBar_ExhaustionTick:Hide();
			CT_BottomBar_ExhaustionLevelFillBar:Hide();
		else
			local exhaustionTickSet = max(((playerCurrXP + exhaustionThreshold) / playerMaxXP) * CT_BottomBar_MainMenuExpBar:GetWidth(), 0);

			CT_BottomBar_ExhaustionTick:ClearAllPoints();

			if (exhaustionTickSet > CT_BottomBar_MainMenuExpBar:GetWidth() or CT_BottomBar_MainMenuBarMaxLevelBar:IsShown()) then
				CT_BottomBar_ExhaustionTick:Hide();
				CT_BottomBar_ExhaustionLevelFillBar:Hide();
			else
				CT_BottomBar_ExhaustionTick:Show();
				CT_BottomBar_ExhaustionTick:SetPoint("CENTER", "CT_BottomBar_MainMenuExpBar", "LEFT", exhaustionTickSet, 0);
				CT_BottomBar_ExhaustionLevelFillBar:Show();
				CT_BottomBar_ExhaustionLevelFillBar:SetPoint("TOPRIGHT", "CT_BottomBar_MainMenuExpBar", "TOPLEFT", exhaustionTickSet, 0);
			end
		end

		if (UnitLevel("player") == MAX_PLAYER_LEVEL) then
			CT_BottomBar_ExhaustionTick:Hide();
		end
	end
	if (event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_EXHAUSTION") then
		local exhaustionStateID = GetRestState();
		if (exhaustionStateID == 1) then
			CT_BottomBar_MainMenuExpBar:SetStatusBarColor(0.0, 0.39, 0.88, 1.0);
			CT_BottomBar_ExhaustionLevelFillBar:SetVertexColor(0.0, 0.39, 0.88, 0.15);
			CT_BottomBar_ExhaustionTickHighlight:SetVertexColor(0.0, 0.39, 0.88);
		elseif (exhaustionStateID == 2) then
			CT_BottomBar_MainMenuExpBar:SetStatusBarColor(0.58, 0.0, 0.55, 1.0);
			CT_BottomBar_ExhaustionLevelFillBar:SetVertexColor(0.58, 0.0, 0.55, 0.15);
			CT_BottomBar_ExhaustionTickHighlight:SetVertexColor(0.58, 0.0, 0.55);
		end

	end
	if (not CT_BottomBar_MainMenuExpBar:IsShown()) then
		CT_BottomBar_ExhaustionTick:Hide();
	end
end

local function CT_BottomBar_ExhaustionToolTipText()
	if (SHOW_NEWBIE_TIPS ~= "1") then
		local x, y = CT_BottomBar_ExhaustionTick:GetCenter();
		if (CT_BottomBar_ExhaustionTick:IsShown()) then
			if (x >= GetScreenWidth() / 2) then
				GameTooltip:SetOwner(CT_BottomBar_ExhaustionTick, "ANCHOR_LEFT");
			else
				GameTooltip:SetOwner(CT_BottomBar_ExhaustionTick, "ANCHOR_RIGHT");
			end
		else
			GameTooltip_SetDefaultAnchor(GameTooltip, UIParent);
		end
	end
	
	local exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier = GetRestState();
	local exhaustionThreshold = GetXPExhaustion();

	exhaustionStateMultiplier = exhaustionStateMultiplier * 100;
	
	local currXP = UnitXP("player");
	local nextXP = UnitXPMax("player");
	local percentXP = math.ceil(currXP / nextXP * 100);

	--local XPText = format(XP_TEXT, currXP, nextXP, percentXP);
	local XPText = format(XP_TEXT, module:breakUpLargeNumbers(currXP), module:breakUpLargeNumbers(nextXP), percentXP);
	local tooltipText = XPText .. format(EXHAUST_TOOLTIP1, exhaustionStateName, exhaustionStateMultiplier);

	-- simplified in CTMod 10.2.7.1 with the earlier depreciation of GetTimeToWellRested() in WoW 10.2.5 and subsequent removal from Classic
	if exhaustionStateID == 4 or exhaustionStateID == 5 then
		tooltipText = tooltipText .. EXHAUST_TOOLTIP2
	end

	if (SHOW_NEWBIE_TIPS ~= "1") then
		GameTooltip:SetText(tooltipText);
	else
		if (GameTooltip.canAddRestStateLine) then
			GameTooltip:AddLine("\n" .. tooltipText);
			GameTooltip:Show();
			GameTooltip.canAddRestStateLine = nil;
		end
	end
end

local function CT_BottomBar_ExhaustionTick_OnUpdate(self, elapsed)
	if (self.timer) then
		if (self.timer < 0) then
			CT_BottomBar_ExhaustionToolTipText();
			self.timer = nil;
		else
			self.timer = self.timer - elapsed;
		end
	end
end

local function CT_BottomBar_MainMenuExpBar_Update()
	local currXP = UnitXP("player");
	local nextXP = UnitXPMax("player");
	CT_BottomBar_MainMenuExpBar:SetMinMaxValues(min(0, currXP), nextXP);
	CT_BottomBar_MainMenuExpBar:SetValue(currXP);
end

local function CT_BottomBar_MainMenuExpBar_CreateDivisionTexture(textureNum)
	totDivisions = totDivisions + 1;
	local texture;
	texture = CT_BottomBar_MainMenuExpBar:CreateTexture("CT_BottomBar_MainMenuExpBarBarDiv" .. textureNum, "OVERLAY", nil, 0);
	texture:SetTexture("Interface\\MainMenuBar\\UI-XP-Bar");
	texture:SetSize(9, 9);
	texture:SetTexCoord(0.01562500, 0.15625000, 0.01562500, 0.17177500); -- original coords
	return texture;
end

local function CT_BottomBar_MainMenuExpBar_Configure()
	local hideBorder;
	local hideDivisions;
	local altBorder;
	local altDivisions;
	local numDivisions;
	if (not appliedOptions) then
		hideBorder = false;
		hideDivisions = false;
		altBorder = false;
		altDivisions = false;
		numDivisions = defDivisions;
	else
		hideBorder = appliedOptions.expBarHideBorder;
		hideDivisions = appliedOptions.expBarHideDivisions;
		altBorder = appliedOptions.exprepAltBorder;
		altDivisions = appliedOptions.exprepAltDivisions;
		numDivisions = appliedOptions.expBarNumDivisions or defDivisions;
	end

	-- Adjust border textures
	local txHeight;
	local showTexture;
	txHeight = 14;
	if (altBorder) then
		showTexture = 2;
	else
		showTexture = 1;
	end
	for i=1, 2 do
		local statBar = CT_BottomBar_MainMenuExpBar;
		local txLeft  = _G["CT_BottomBar_MainMenuExpBarTextureLeftCap" .. i];
		local txRight = _G["CT_BottomBar_MainMenuExpBarTextureRightCap" .. i];
		local txMid   = _G["CT_BottomBar_MainMenuExpBarTextureMid" .. i];
		local x1, x2, y1, y2;
		if (showTexture == 1) then
			-- Use Experience Bar texture
			txLeft:SetTexture("Interface\\MainMenuBar\\UI-XP-Bar");
			txLeft:SetHeight(txHeight);
			txLeft:SetWidth(14);
			txLeft:SetPoint("LEFT", statBar, "LEFT", -3, 0);
			txLeft:SetTexCoord(0.18750000, 0.43750000, 0.01562500, 0.26562500);

			txRight:SetTexture("Interface\\MainMenuBar\\UI-XP-Bar");
			txRight:SetHeight(txHeight);
			txRight:SetWidth(14);
			txRight:SetPoint("RIGHT", statBar, "RIGHT", 3, 0);
			txRight:SetTexCoord(0.18750000, 0.43750000, 0.29687500, 0.54687500);

			txMid:SetTexture("Interface\\MainMenuBar\\UI-XP-Mid");
			txMid:SetHeight(txHeight);
			txMid:SetWidth(14);
			txMid:SetPoint("LEFT", txLeft, "RIGHT", 0, 0);
			txMid:SetPoint("RIGHT", txRight, "LEFT", 0, 0);
			txMid:SetTexCoord(0, 1, 0, 1);
		else
			-- Use Reputation Watch Bar texture
			txLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-ReputationWatchBar");
			txLeft:SetHeight(txHeight);
			txLeft:SetWidth(14);
			txLeft:SetPoint("LEFT", statBar, "LEFT", -1, 0);
			x1 = 54 / 256;
			x2 = 66 / 256;
			y1 = 1 / 64;
			y2 = 12 / 64;
			txLeft:SetTexCoord(x1, y1, x1, y2, x2, y1, x2, y2);

			txRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-ReputationWatchBar");
			txRight:SetHeight(txHeight);
			txRight:SetWidth(14);
			txRight:SetPoint("RIGHT", statBar, "RIGHT", 1, 0);
			x1 = 94 / 256;
			x2 = 106 / 256;
			y1 = 1 / 64;
			y2 = 12 / 64;
			txRight:SetTexCoord(x1, y1, x1, y2, x2, y1, x2, y2);

			txMid:SetTexture("Interface\\PaperDollInfoFrame\\UI-ReputationWatchBar");
			txMid:SetHeight(txHeight);
			txMid:SetWidth(14);
			txMid:SetPoint("LEFT", txLeft, "RIGHT", 0, 0);
			txMid:SetPoint("RIGHT", txRight, "LEFT", 0, 0);
			x1 = 72 / 256;
			x2 = 96 / 256;
			y1 = 1 / 64;
			y2 = 12 / 64;
			txMid:SetTexCoord(x1, y1, x1, y2, x2, y1, x2, y2);
		end
		local hide;
		if (hideBorder) then
			hide = true;
		else
			if (altDivisions) then
				hide = (i == 1);
			else
				hide = (i == 2);
			end
		end
		if (hide) then
			txLeft:Hide();
			txRight:Hide();
			txMid:Hide();
		else
			txLeft:Show();
			txRight:Show();
			txMid:Show();
		end
	end
	if (updateDefaultBar) then
		-- Hide the border textures for Blizzard's exp bar.
		if (hideBorder) then
			MainMenuXPBarTextureLeftCap:Hide();
			MainMenuXPBarTextureRightCap:Hide();
			MainMenuXPBarTextureMid:Hide();
		else
			MainMenuXPBarTextureLeftCap:Show();
			MainMenuXPBarTextureRightCap:Show();
			MainMenuXPBarTextureMid:Show();
		end
	end

	-- Adjust division textures
	local divHeight;
	if (hideBorder) then
		if (altDivisions) then
			divHeight  = 10.4;
			divOffsetY = 0;
		else
			divHeight  = 10.4;
			divOffsetY = 0;
		end
	else
		if (altDivisions) then
			divHeight  = 7;
			divOffsetY = 0;
		else
			divHeight  = 8.5;
			divOffsetY = 1.1;
		end
	end
	for i=1, numDivisions-1 do
		local texture = _G["CT_BottomBar_MainMenuExpBarBarDiv" .. i];
		if (not texture) then
			texture = CT_BottomBar_MainMenuExpBar_CreateDivisionTexture(i);
		end
		texture:SetSize(9, divHeight);
		if (altDivisions or hideBorder) then
			texture:SetTexCoord( 0.01562500, 0.15625000, 0.04962500, 0.17177500);
		else
			texture:SetTexCoord( 0.01562500, 0.15625000, 0.01562500, 0.17177500); -- original coords
		end
		if (hideDivisions) then
			texture:Hide();
		else
			texture:Show();
		end
	end
	for i=numDivisions, totDivisions do
		local texture = _G["CT_BottomBar_MainMenuExpBarBarDiv" .. i];
		if (texture) then
			texture:Hide();
		end
	end
	if (updateDefaultBar) then
		-- Hide the division textures for Blizzard's exp bar.
		for i=1, 19 do
			local texture = _G["MainMenuXPBarDiv" .. i];
			if (texture) then
				if (hideDivisions) then
					texture:Hide();
				else
					texture:Show();
				end
			end
		end
	end
end

local function CT_BottomBar_MainMenuExpBar_SetWidth(width)
	CT_BottomBar_MainMenuExpBarTextureMid1:SetWidth(width-28);
	CT_BottomBar_MainMenuExpBarTextureMid2:SetWidth(width-28);
	
	local numDivisions;
	if (appliedOptions) then
		numDivisions = appliedOptions.expBarNumDivisions or defDivisions;
	else
		numDivisions = defDivisions;
	end
	local divWidth = width / numDivisions;
	local xpos = divWidth - 4.5;
	for i=1, numDivisions-1 do
		local texture = _G["CT_BottomBar_MainMenuExpBarBarDiv" .. i];
		if (not texture) then
			texture = CT_BottomBar_MainMenuExpBar_CreateDivisionTexture(i);
		end
		local xalign = floor(xpos);
		texture:SetPoint("LEFT", xalign, divOffsetY);
		xpos = xpos + divWidth;
	end		

	CT_BottomBar_MainMenuExpBar:SetWidth(width);
	if CT_BottomBar_ExhaustionTick then
		CT_BottomBar_ExhaustionTick_OnEvent(CT_BottomBar_ExhaustionTick, "UPDATE_EXHAUSTION");
	end
	CT_BottomBar_MainMenuBarMaxLevelBar:SetWidth(width);
end

local function CT_BottomBar_ExpBar_MakeVisible()
	-- This makes our exp bar visible.
	local ourExpBar = CT_BottomBar_MainMenuExpBar;
	local ourExpTick = CT_BottomBar_ExhaustionTick;
	ourExpBar:SetAlpha(1);
	ourExpBar:EnableMouse(true);
	ourExpTick:SetAlpha(1);
	ourExpTick:EnableMouse(true);
end

local function CT_BottomBar_ExpBar_MakeInvisible()
	-- This makes our exp bar invisible.
	local ourExpBar = CT_BottomBar_MainMenuExpBar;
	local ourExpTick = CT_BottomBar_ExhaustionTick;
	ourExpBar:SetAlpha(0);
	ourExpBar:EnableMouse(false);
	ourExpTick:SetAlpha(0);
	ourExpTick:EnableMouse(false);
end

local function CT_BottomBar_MainMenuExpBar_CreateFrames()
	local tx;
	local overlayFrame, barText;
	local experBar;
	local maxFrame;
	local exhFrame;

	-----
	-- Experience bar
	-----
	experBar = CreateFrame("StatusBar", "CT_BottomBar_MainMenuExpBar", UIParent, "TextStatusBar");
	experBar:SetWidth(defBarWidth);
	experBar:SetHeight(11);
	experBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
	experBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	experBar:SetStatusBarColor(0.58, 0.0, 0.55);

	experBar:SetScript("OnEvent",
		function(self, event, ...)
			if (event == "CVAR_UPDATE") then
				TextStatusBar_OnEvent(self, event, ...);
			else
				CT_BottomBar_MainMenuExpBar_Update();
			end
		end
	);

	experBar:SetScript("OnShow",
		function(self)
			if (GetCVar("xpBarText") == "1") then
				TextStatusBar_UpdateTextString(self);
			end
		end
	);

	experBar:SetScript("OnEnter",
		function(self)
			TextStatusBar_UpdateTextString(self);
			ShowTextStatusBarText(self);
			CT_BottomBar_ExhaustionTick.timer = 1;
			local label = XPBAR_LABEL;
			if (IsTrialAccount()) then
				local rLevel = GetRestrictedAccountData();
				if (UnitLevel("player") >= rLevel) then
					label = label.." "..RED_FONT_COLOR_CODE..TRIAL_CAPPED.."|r";
				end
			end
	
			GameTooltip_AddNewbieTip(self, label, 1.0, 1.0, 1.0, NEWBIE_TOOLTIP_XPBAR, 1);
			GameTooltip.canAddRestStateLine = 1;
			CT_BottomBar_ExhaustionToolTipText();
		end
	);

	experBar:SetScript("OnLeave",
		function(self)
			HideTextStatusBarText(self);
			GameTooltip:Hide();
			CT_BottomBar_ExhaustionTick.timer = nil;
		end
	);

	experBar:SetScript("OnUpdate",
		function(self, elapsed)
			CT_BottomBar_ExhaustionTick_OnUpdate(CT_BottomBar_ExhaustionTick, elapsed);
		end
	);

	experBar:SetScript("OnValueChanged",
		function(self)
			if (not self:IsShown()) then
				return;
			end
			TextStatusBar_OnValueChanged(self);
		end
	);
	
	hooksecurefunc("TextStatusBar_UpdateTextStringWithValues",
		function()
			if (module.ctExpBar and module.ctExpBar.isDisabled) then
				experBar:Hide();		-- Counteracts line 50 of TextStatusBar.lua when the custom XP bar isn't being used
			end
		end
	);

	tx = experBar:CreateTexture("CT_BottomBar_ExhaustionLevelFillBar", "BORDER");
	tx:SetHeight(10);
	tx:SetWidth(0);
	tx:SetPoint("TOPLEFT", experBar, "TOPLEFT", 0, 0);
	tx:SetColorTexture(1, 1, 1, 1);

	-- Border texture with a sublevel of -1 (below division textures which are at sublevel 0).
	tx = experBar:CreateTexture("CT_BottomBar_MainMenuExpBarTextureLeftCap1",  "OVERLAY", nil, -1);
	tx = experBar:CreateTexture("CT_BottomBar_MainMenuExpBarTextureRightCap1", "OVERLAY", nil, -1);
	tx = experBar:CreateTexture("CT_BottomBar_MainMenuExpBarTextureMid1",      "OVERLAY", nil, -1);

	-- Border texture with a sublevel of 1 (above division textures which are at sublevel 0).
	tx = experBar:CreateTexture("CT_BottomBar_MainMenuExpBarTextureLeftCap2",  "OVERLAY", nil,  1);
	tx = experBar:CreateTexture("CT_BottomBar_MainMenuExpBarTextureRightCap2", "OVERLAY", nil,  1);
	tx = experBar:CreateTexture("CT_BottomBar_MainMenuExpBarTextureMid2",      "OVERLAY", nil,  1);

	tx = experBar:CreateTexture("CT_BottomBar_MainMenuExpBarTextureBack", "BACKGROUND");
	tx:SetColorTexture(0, 0, 0, 0.5);
	tx:SetAllPoints();

	overlayFrame = CreateFrame("Frame", "CT_BottomBar_MainMenuExpBarOverlayFrame", experBar);
	overlayFrame:SetFrameStrata("DIALOG");

	barText = overlayFrame:CreateFontString("CT_BottomBar_MainMenuExpBarExpText", "ARTWORK", "TextStatusBarText");
	barText:SetPoint("CENTER", experBar, "CENTER", 0, 1);

	-----
	-- Maximum level bar
	-----
	maxFrame = CreateFrame("Frame", "CT_BottomBar_MainMenuBarMaxLevelBar", UIParent);
	maxFrame:EnableMouse(true);
	maxFrame:Hide();
	maxFrame:SetHeight(7);
	maxFrame:SetWidth(defBarWidth);
	maxFrame:SetPoint("TOP", UIParent, "TOP", 0, -11);

	tx = maxFrame:CreateTexture("CT_BottomBar_MainMenuMaxLevelBarTexture", "BACKGROUND");
	tx:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-MaxLevel");
	tx:SetHeight(7);
	tx:SetWidth(256);
	tx:SetTexCoord(0, 1.0, 0, 0.21875);
	tx:SetPoint("BOTTOMLEFT", maxFrame, "TOPLEFT", 0, 0);
	tx:SetPoint("BOTTOMRIGHT", maxFrame, "TOPRIGHT", 0, 0);

	maxFrame:SetScript("OnShow",
		function(self)
			UIParent_ManageFramePositions();
		end
	);

	maxFrame:SetScript("OnHide",
		function(self)
			UIParent_ManageFramePositions();
		end
	);

	-----
	-- Exhaustion tick
	-----
	exhFrame = CreateFrame("Button", "CT_BottomBar_ExhaustionTick", CT_BottomBar_MainMenuExpBar);
	exhFrame:SetFrameStrata("DIALOG");
	exhFrame:SetHeight(32);
	exhFrame:SetWidth(32);
	exhFrame:SetPoint("CENTER", CT_BottomBar_MainMenuExpBar, "CENTER", 0, 0);

	exhFrame:SetScript("OnEvent",
		function(self, event, ...)
			CT_BottomBar_ExhaustionTick_OnEvent(self, event, ...);
		end
	);

	exhFrame:SetScript("OnEnter",
		function()
			CT_BottomBar_ExhaustionToolTipText();
		end
	);

	exhFrame:SetScript("OnLeave",
		function()
			GameTooltip_Hide();
		end
	);

	tx = exhFrame:CreateTexture("CT_BottomBar_ExhaustionTickNormal");
	tx:SetTexture("Interface\\MainMenuBar\\UI-ExhaustionTickNormal");
	tx:SetAllPoints();
	exhFrame:SetNormalTexture(tx);

	tx = exhFrame:CreateTexture("CT_BottomBar_ExhaustionTickHighlight");
	tx:SetTexture("Interface\\MainMenuBar\\UI-ExhaustionTickHighlight");
	tx:SetBlendMode("ADD");
	tx:SetAllPoints();
	exhFrame:SetHighlightTexture(tx);

	-- CT_BottomBar_ExhaustionTick:OnLoad
	exhFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	exhFrame:RegisterEvent("PLAYER_XP_UPDATE");
	exhFrame:RegisterEvent("UPDATE_EXHAUSTION");
	exhFrame:RegisterEvent("PLAYER_LEVEL_UP");
	exhFrame:RegisterEvent("PLAYER_UPDATE_RESTING");

	-- CT_BottomBar_MainMenuExpBarOverlayFrame:OnLoad
	experBar.lockShow = 0;
	SetTextStatusBarText(experBar, CT_BottomBar_MainMenuExpBarExpText);
	CT_BottomBar_MainMenuExpBar_Update();

	-- CT_BottomBar_MainMenuExpBar:OnLoad
	TextStatusBar_Initialize(experBar);
	experBar:RegisterEvent("PLAYER_ENTERING_WORLD");
	experBar:RegisterEvent("PLAYER_XP_UPDATE");
	experBar.textLockable = 1;
	experBar.cvar = "xpBarText";
	experBar.cvarLabel = "XP_BAR_TEXT";
	experBar.alwaysPrefix = true;

	-- CharacterFrame:OnLoad
	SetTextStatusBarTextPrefix(experBar, XP);
	TextStatusBar_UpdateTextString(experBar);

	CharacterFrame:HookScript("OnShow",
		function(self)
			CT_BottomBar_MainMenuExpBar.showNumeric = true;
			ShowTextStatusBarText(CT_BottomBar_MainMenuExpBar);
		end
	);

	CharacterFrame:HookScript("OnHide",
		function(self)
			CT_BottomBar_MainMenuExpBar.showNumeric = nil;
			HideTextStatusBarText(CT_BottomBar_MainMenuExpBar);
		end
	);

	maxFrame:Hide();
	exhFrame:Show();
	experBar:Hide();
end

--------------------------------------------
-- Experience Bar addon

local isExpOnSpecialUI;

local function addon_isDisabled()
	local ctExpBar = module.ctExpBar;
	if (ctExpBar) then
		return ctExpBar.isDisabled;
	else
		return true;
	end
end

function module:CT_BottomBar_ExpBar_GetHideExperienceBar()
	-- Returns true if we want the exp bar to be hidden, else false.
	local hideExperienceBar = appliedOptions["Experience Bar"];
	-- If player does not want to hide the exp bar...
	if (not hideExperienceBar) then
		-- If the player is at max level...
		if (UnitLevel("player") == MAX_PLAYER_LEVEL) then
			-- If we don't want to show the xp bar at max level...
			if (appliedOptions.expBarHideAtMaxLevel) then
				-- Hide the exp bar.
				hideExperienceBar = true;
			end
		end
		-- If player has disabled xp gain...
		--[[
		if (IsXPUserDisabled()) then
			-- If we don't want to show the exp bar when xp gain is disabled...
			if (appliedOptions.expBarHideAtMaxLevel) then
				-- Hide the exp bar.
				hideExperienceBar = true;
			end
		end
		--]]
	end
	return hideExperienceBar;
end

function module:CT_BottomBar_ExpBar_GetspecialType()
--[[
	-- Get the type of special UI frame ("petbattle", "vehicle", "override", "none").
	local specialType;
--	if (UnitHasVehicleUI("player")) then
	if (module:hasPetBattleUI()) then
		specialType = "petbattle";
	elseif (module:hasVehicleUI()) then
		specialType = "vehicle";
--	elseif (not module.actionBarDisabled) then
--		if (module:hasOverrideUI()) then
--			specialType = "override";
--		else
--			specialType = "none";
--		end
	elseif (module:hasOverrideUI()) then
		specialType = "override";
	else
		specialType = "none";
	end
	return specialType;
--]]
	return "none"
end

function module:CT_BottomBar_ExpBar_CanShowExpOnSpecialUI(specialType)
	-- NOTE: If result is true, check if the exp bar is to be hidden before displaying the exp bar
	-- on the special UI frame. (see CT_BottomBar_ExpBar_GetHideExperienceBar).
	local canShowExpOnSpecial = false;
	local specialUI;
	if (specialType == "petbattle") then
		local hideSpecial = appliedOptions.petbattleHideFrame;
		local hideExpOnSpecial = appliedOptions.expBarHideOnPetBattle;
		specialUI = true;
	elseif (specialType == "vehicle") then
		local hideSpecial = appliedOptions.vehicleHideFrame;
		local hideExpOnSpecial = appliedOptions.expBarHideOnOther;
		specialUI = true;
	elseif (specialType == "override") then
		local hideSpecial = appliedOptions.overrideHideFrame;
		local hideExpOnSpecial = appliedOptions.expBarHideOnOther;
		specialUI = true;
	end
	if (specialUI) then
		if (not hideSpecial and not hideExpOnSpecial) then
			-- We can show the exp bar on the special UI frame.
			canShowExpOnSpecial = true;
		end
	end
	return canShowExpOnSpecial;
end

function module:CT_BottomBar_ExpBar_IsExpOnSpecialUI()
	return isExpOnSpecialUI;
end

function module:CT_BottomBar_ExpBar_SetWidth(width)
	if (addon_isDisabled()) then
		return;
	end
	if (tempWidth) then
		width = tempWidth;
	end
	CT_BottomBar_MainMenuExpBar_SetWidth(width or appliedOptions.expBarWidth or defBarWidth);
end

function module:CT_BottomBar_ExpBar_GetWidth(ignoreTemp)
	local width;
	width = appliedOptions.expBarWidth;
	if (tempWidth and (not ignoreTemp)) then
		width = tempWidth;
	end
	return width;
end

function module:CT_BottomBar_ExpBar_Configure()
	if (addon_isDisabled()) then
		return;
	end
	CT_BottomBar_MainMenuExpBar_Configure();
	module:CT_BottomBar_ExpBar_SetWidth();
end

local function addon_UpdateOurUI(self)
	-- Update the experience bar when player does not have a special UI.
	-- self == experience bar object
	isExpOnSpecialUI = false;

	local objExp = CT_BottomBar_MainMenuExpBar;
	local objMax = CT_BottomBar_MainMenuBarMaxLevelBar;

	objExp:ClearAllPoints();
	setparent(objExp, self.frame);
	objExp:EnableMouse(true);
	setpoint(objExp, "BOTTOMLEFT", self.frame, 0, 0);
	objExp:SetFrameLevel(objExp:GetParent():GetFrameLevel());

	CT_BottomBar_ExpBar_MakeVisible();

	tempWidth = nil;
	module:CT_BottomBar_ExpBar_Configure();

	objMax:ClearAllPoints();
	setparent(objMax, self.frame);
--	setpoint(objMax, "TOPLEFT", objExp);
	setpoint(objMax, "TOPLEFT", objExp, "TOPLEFT", 0, -11);
end

local function addon_OverrideActionBar_CalcSize()
	-- This is a modified version of OverrideActionBar_CalcSize() from OverrideActionBar.lua
	local width, xpWidth, anchor, buttonAnchor;
	local hasPitch = IsVehicleAimAngleAdjustable();
	local hasExit =  CanExitVehicle();
	if hasExit and hasPitch then
		width, xpWidth, anchor, buttonAnchor = 1020, 580, 103, -234;
	elseif hasPitch then
		width, xpWidth, anchor, buttonAnchor = 945, 500, 145, -192;
	elseif hasExit then
		width, xpWidth, anchor, buttonAnchor = 930, 490, 60, -277;
	else
		width, xpWidth, anchor, buttonAnchor = 860, 460, 100, -237;
	end
	return width, xpWidth, anchor, buttonAnchor;
end

local function addon_UpdateOverrideUI(self)
	-- Update the experience bar frame for an override UI.
	-- self == exp bar object
	local ourExpBar = CT_BottomBar_MainMenuExpBar;
	local specialBar = OverrideActionBar;
	local specialExpBar = OverrideActionBarExpBar;

	-- Show our exp bar on the special UI.
	isExpOnSpecialUI = true;

	-- Don't parent our exp bar to the special UI's bar otherwise we may have positioning
	-- issues when Blizzard animates the special UI's frame on/off screen.
	--setparent(ourExpBar, specialBar);
	--ourExpBar:EnableMouse(true);

	-- Anchor our exp bar to the special UI.
	ourExpBar:ClearAllPoints();
	setpoint(ourExpBar, "BOTTOM", specialBar, "TOP", 0, 0);

	-- Determine what width our exp bar should be.
	local width, xpWidth, anchor, buttonAnchor = addon_OverrideActionBar_CalcSize();
	tempWidth = xpWidth + 16;

	-- Configure our exp bar
	module:CT_BottomBar_ExpBar_Configure();

	-- Make sure our exp bar is above the special UI.
	ourExpBar:SetFrameLevel(specialBar:GetFrameLevel()+1);

	-- Adjust visibility of our exp bar based on whether or not the
	-- special UI frame is hidden.
	-- Blizzard sometimes puts you in a vehicle, but keeps the frame hidden
	-- for a while before showing it.
	-- An example of this is the "Unleash Hell" quest in Mists of Pandaria
	-- for Alliance players. It is one of the first quests you do at 85.
	-- You are put in the vehicle, but the vehicle frame isn't shown until
	-- the characters stop talking. Also during the quest, the vehicle frame
	-- will get hidden temporarily as you move from area to area.
	if (specialBar:IsShown()) then
		CT_BottomBar_ExpBar_MakeVisible();
	else
		CT_BottomBar_ExpBar_MakeInvisible();
	end
end

local function addon_UpdatePetBattleUI(self)
	-- Update the experience bar frame for a pet battle UI.
	-- self == exp bar object
	local ourExpBar = CT_BottomBar_MainMenuExpBar;
	local specialBar = PetBattleFrame.BottomFrame;
	local specialExpBar = PetBattleFrame.BottomFrame.xpBar;

	-- Show our exp bar on the special UI.
	isExpOnSpecialUI = true;

	-- Don't parent our exp bar to the special UI's bar otherwise we may have positioning
	-- issues when Blizzard animates the special UI's frame on/off screen.
	--setparent(ourExpBar, specialBar);
	--ourExpBar:EnableMouse(true);

	-- Anchor our exp bar to the special UI.
	ourExpBar:ClearAllPoints();
	setpoint(ourExpBar, "BOTTOM", specialBar, "TOP", 0, 7);

	-- Determine what width our exp bar should be.
	local xpWidth = specialExpBar:GetWidth() or 504;  -- from Blizzard_PetBattleUI.xml
	tempWidth = xpWidth;

	-- Configure our exp bar
	module:CT_BottomBar_ExpBar_Configure();

	-- Make sure our exp bar is above the special UI.
	ourExpBar:SetFrameLevel(specialBar:GetFrameLevel()+1);

	-- Adjust visibility of our exp bar based on whether or not the
	-- special UI frame is hidden.
	-- Blizzard may keep the frame hidden for a while before showing it.
	if (specialBar:IsShown()) then
		CT_BottomBar_ExpBar_MakeVisible();
	else
		CT_BottomBar_ExpBar_MakeInvisible();
	end
end

local function addon_disableDefaultExpBars()
	-- Disable the default exp bars.

	-- Change alpha, etc, but don't Hide() them.
	-- Blizzard's code checks IsShown() to manipulate the position
	-- of some other frames.
	MainMenuExpBar:SetAlpha(0);
	MainMenuExpBar:EnableMouse(false);
	MainMenuBarMaxLevelBar:SetAlpha(0);
	MainMenuBarMaxLevelBar:EnableMouse(false);
	ExhaustionTick:SetAlpha(0);
	ExhaustionTick:EnableMouse(false);

	ReputationWatchBar:SetAlpha(0);
	ReputationWatchBar:EnableMouse(false);

	--[[
	local specialExpBar = OverrideActionBarExpBar;
	specialExpBar.ctInUse = true
	specialExpBar.ctUseAlpha = 0;
	specialExpBar.ctUseMouse = false;
	module.frame_SetAlpha(specialExpBar, specialExpBar.ctUseAlpha);
	module.frame_EnableMouse(specialExpBar, specialExpBar.ctUseMouse);

	local specialExpBar = PetBattleFrame.BottomFrame.xpBar;
	specialExpBar:SetAlpha(0);
	specialExpBar:EnableMouse(false);
	--]]
end

local function addon_enableDefaultExpBars()
	-- Enable the default exp bars.

	-- Change alpha, etc, but don't Show() them.
	-- Blizzard's code checks IsShown() to manipulate the position
	-- of some other frames.
	MainMenuExpBar:SetAlpha(1);
	MainMenuExpBar:EnableMouse(true);
	MainMenuBarMaxLevelBar:SetAlpha(1);
	MainMenuBarMaxLevelBar:EnableMouse(true);
	ExhaustionTick:SetAlpha(1);
	ExhaustionTick:EnableMouse(true);

	ReputationWatchBar:SetAlpha(1);
	ReputationWatchBar:EnableMouse(true);

	--[[
	local specialExpBar = OverrideActionBarExpBar;
	specialExpBar.ctInUse = nil;
	module.frame_SetAlpha(specialExpBar, 1);
	module.frame_EnableMouse(specialExpBar, true);

	local specialExpBar = PetBattleFrame.BottomFrame.xpBar;
	specialExpBar:SetAlpha(1);
	specialExpBar:EnableMouse(true);
	--]]
end

local function addon_updateDefaultExpBars()
	if (addon_isDisabled()) then
		return;
	end
	-- Keep Blizzard's exp bar "disabled" while ours is activated.
	addon_disableDefaultExpBars();
end

local function addon_Update(self)
	-- Update the experience bar frame
	-- self == exp bar object
	if (isBusy()) then
		setDelayedUpdate(1);
		return;
	end

	-- Check for a special UI.
	local specialFunc;
	local hideSpecial;
	local hideExpOnSpecial;
	local hideExperienceBar = module:CT_BottomBar_ExpBar_GetHideExperienceBar();
	local specialType = module:CT_BottomBar_ExpBar_GetspecialType();
	if (specialType == "petbattle") then
		hideSpecial = appliedOptions.petbattleHideFrame;
		hideExpOnSpecial = appliedOptions.expBarHideOnPetBattle;
		specialFunc = addon_UpdatePetBattleUI;
	elseif (specialType == "vehicle") then
		hideSpecial = appliedOptions.vehicleHideFrame;
		hideExpOnSpecial = appliedOptions.expBarHideOnOther;
		specialFunc = addon_UpdateOverrideUI;
	elseif (specialType == "override") then
		hideSpecial = appliedOptions.overrideHideFrame;
		hideExpOnSpecial = appliedOptions.expBarHideOnOther;
		specialFunc = addon_UpdateOverrideUI;
	end
	-- If we have a special UI, and we're not hiding the special UI frame...
	if (specialFunc and not hideSpecial) then
		-- Update the special UI
		specialFunc(self);
		-- Update the game's default exp bars
		addon_updateDefaultExpBars();
		-- If player does not want to suppress the exp bar on a special UI...
		if (not hideExpOnSpecial) then
			-- We either showed or hid our exp bar on the special UI.
			-- We're all done.
			return;
		end
		-- We did not show (or hide) our exp bar on the special UI.
		-- Fall through to display our exp bar where it was placed by the player.
	end

	-- Exp bar is not to be shown on a special UI frame.
	-- Position the frames where we want them.

	local objExp = CT_BottomBar_MainMenuExpBar;
--	local objMax = CT_BottomBar_MainMenuBarMaxLevelBar;

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", objExp, 0, 0);
	self.helperFrame:SetPoint("BOTTOMRIGHT", objExp);

	addon_UpdateOurUI(self);
	addon_updateDefaultExpBars();
	return;
end

local function addon_OnDelayedUpdate(self, value)
	-- Perform a delayed update.
	-- self == exp bar object
	-- value == value that was passed to module:setDelayedUpdate()
	-- Returns: true if delayed update was completed.
	--          false, nil == the delayed update was not completed.
	
	-- Call Blizzard's ReputationWatchBar_UpdateMaxLevel() function.
	-- Since we have this hooked (in CT_BottomBar_Rep.lua),
	-- our exp and rep bars will also get updated.
	(ReputationWatchBar_UpdateMaxLevel or ReputationWatchBar_Update)();  -- classic era vs cata

	return true;
end

local function addon_updateVisibility()
	-- This will get called at the end of addon:updateVisibility().
	-- Call Blizzard's function that updates the reputation and exp bars.
	(ReputationWatchBar_UpdateMaxLevel or ReputationWatchBar_Update)();
end

local function addon_Hooked_SpecialUI_OnShow(self)
	-- Hook of a special UI frame's OnShow script.
	-- Update the exp bar. This ensures proper visibility of the exp bar.
	addon_Update(ctAddon);
end

local function addon_Hooked_SpecialUI_OnHide(self)
	-- Hook of a special UI frame's OnHide script.
	-- Update the exp bar. This ensures proper visibility of the exp bar.
	addon_Update(ctAddon);
end

local function addon_Enable(self)
	-- Perform special actions when this bar gets enabled.
	module:CT_BottomBar_ExpBar_Configure();
	addon_updateDefaultExpBars();

	setDelayedUpdate(1);
end

local function addon_Disable(self)
	-- Perform special actions when this bar gets disabled.

	-- Enable the default exp bars.
	addon_enableDefaultExpBars();

	-- Hide our exp bar.
	CT_BottomBar_MainMenuExpBar:Hide();
	CT_BottomBar_MainMenuBarMaxLevelBar:Hide();
	CT_BottomBar_ReputationWatchBar:Hide();

	setDelayedUpdate(1);
end

local function addon_Init(self)
	-- Initialization
	-- self == exp bar object

	appliedOptions = module.appliedOptions;

	ctAddon = self;
	module.ctExpBar = self;
	module.CT_BottomBar_MainMenuExpBar_Update = addon_Update;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	setpoint = frame.SetPoint;
	setparent = frame.SetParent;

	-- Don't need to hook much if anything here. Most of the hooks done in
	-- the reputation bar addon will cause both the rep and exp bars to udpate.
	
	local specialBar;

	--[[
	specialBar = OverrideActionBar;
	if (specialBar) then
		specialBar:HookScript("OnShow", addon_Hooked_SpecialUI_OnShow);
		specialBar:HookScript("OnHide", addon_Hooked_SpecialUI_OnHide);
	end


	specialBar = PetBattleFrame.BottomFrame;
	if (specialBar) then
		specialBar:HookScript("OnShow", addon_Hooked_SpecialUI_OnShow);
		specialBar:HookScript("OnHide", addon_Hooked_SpecialUI_OnHide);
	end
	--]]
	
	return true;
end

local function addon_Register()
	module:registerAddon(
		"Experience Bar",  -- option name
		"ExpBar",  -- used in frame names
		module.text["CT_BottomBar/Options/ExpBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/ExpBar"],  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -512, 42 },
		{ -- settings
			orientation = "ACROSS",
			--[[
			usedOnVehicleUI = true,
			showOnVehicleUI = true,  -- Need this because we're not parenting our exp bar to the vehicle UI frame.
			usedOnOverrideUI = true,
			showOnOverrideUI = true,  -- Need this because we're not parenting our exp bar to the override UI frame.
			usedOnPetBattleUI = true,
			showOnPetBattleUI = true,  -- Need this because we're not parenting our exp bar to the pet battle UI frame.
			--]]
			updateVisibility = addon_updateVisibility,
			OnDelayedUpdate = addon_OnDelayedUpdate,
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		addon_Disable,
		"helperFrame",
		CT_BottomBar_MainMenuExpBar,
		CT_BottomBar_MainMenuBarMaxLevelBar
	);
end

if (not StatusTrackingBarMixin) then
	CT_BottomBar_MainMenuExpBar_CreateFrames();
	module.loadedAddons["Experience Bar"] = addon_Register;
end
