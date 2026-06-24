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

local setparent;

local defDivisions = 20;
local defBarWidth = EXP_DEFAULT_WIDTH or 1024;

local showingRepOnExp;
local divOffsetY = 0;
local totDivisions = 0;

--------------------------------------------
-- Misc

local function isBusy()
	return module:isBlizzardAnimating();
end

local function setDelayedUpdate(value)
	module:setDelayedUpdate(ctAddon, value);
end

--------------------------------------------
-- Reputation Bar
--
-- The reputation bar is a modified version of
-- Blizzard's reputation bar from ReputationBarFrame.lua
-- and ReputationBarFrame.xml.
--
-- A modified bar was needed in WoW 4 to avoid positioning
-- issues with the default exp bar when Blizzard animates
-- the default exp bar on/off the screen. Attempting
-- to move the exp bar, re-parent it, etc during the
-- animation can lead to various elements of the bar
-- being positioned incorrectly after the animation
-- ends.

local function CT_BottomBar_HideWatchedReputationBarText(unlock)
	if ( unlock or not CT_BottomBar_ReputationWatchBar.cvarLocked ) then
		CT_BottomBar_ReputationWatchBar.cvarLocked = nil;
		CT_BottomBar_ReputationWatchStatusBarText:Hide();
		CT_BottomBar_ReputationWatchBar.textLocked = nil;
	end
end

local function CT_BottomBar_ShowWatchedReputationBarText(lock)
	if ( lock ) then
		CT_BottomBar_ReputationWatchBar.cvarLocked = lock;
	end
	if ( CT_BottomBar_ReputationWatchBar:IsShown() ) then
		CT_BottomBar_ReputationWatchStatusBarText:Show();
		CT_BottomBar_ReputationWatchBar.textLocked = 1;
	else
		CT_BottomBar_HideWatchedReputationBarText();
	end
end

local function CT_BottomBar_ReputationWatchBar_CreateDivisionTexture(textureNum)
	totDivisions = totDivisions + 1;
	local texture;
	texture = CT_BottomBar_ReputationWatchStatusBar:CreateTexture("CT_BottomBar_ReputationWatchBarDiv" .. textureNum, "OVERLAY", nil, 0);
	texture:SetTexture("Interface\\MainMenuBar\\UI-XP-Bar");
	texture:SetSize(9, 9);
	texture:SetTexCoord( 0.01562500, 0.15625000, 0.01562500, 0.17177500); -- original coords
	return texture;
end

local function CT_BottomBar_ReputationWatchBar_Configure()
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
		hideBorder = appliedOptions.repBarHideBorder;
		hideDivisions = appliedOptions.repBarHideDivisions;
		altBorder = appliedOptions.exprepAltBorder;
		altDivisions = appliedOptions.exprepAltDivisions;
		numDivisions = appliedOptions.repBarNumDivisions or defDivisions;
	end

	-- Adjust border textures
	local txHeight;
	local showTexture;
	if (showingRepOnExp) then
		txHeight = 14;
		if (altBorder) then
			showTexture = 2;
		else
			showTexture = 1;
		end
	else
		txHeight = 11;
		showTexture = 2;
	end
	for i=1, 2 do
		local statBar = CT_BottomBar_ReputationWatchStatusBar;
		local txLeft  = _G["CT_BottomBar_ReputationWatchBarTextureLeftCap" .. i];
		local txRight = _G["CT_BottomBar_ReputationWatchBarTextureRightCap" .. i];
		local txMid   = _G["CT_BottomBar_ReputationWatchBarTextureMid" .. i];
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
			txLeft:SetPoint("LEFT", statBar, "LEFT",  -1, 0);
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

	-- Adjust division textures
	local divHeight;
	if (showingRepOnExp) then
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
	else
		if (hideBorder) then
			if (altDivisions) then
				divHeight  = 8;
				divOffsetY = 0;
			else
				divHeight  = 7.6;
				divOffsetY = 0;
			end
		else
			if (altDivisions) then
				divHeight  = 8;
				divOffsetY = 0;
			else
				divHeight  = 7.6;
				divOffsetY = 0.5;
			end
		end
	end
	for i=1, numDivisions-1 do
		local texture = _G["CT_BottomBar_ReputationWatchBarDiv" .. i];
		if (not texture) then
			texture = CT_BottomBar_ReputationWatchBar_CreateDivisionTexture(i);
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
		local texture = _G["CT_BottomBar_ReputationWatchBarDiv" .. i];
		if (texture) then
			texture:Hide();
		end
	end
end

local function CT_BottomBar_ReputationWatchBar_SetWidth(width)
	CT_BottomBar_ReputationWatchBarTextureMid1:SetWidth(width-28);
	CT_BottomBar_ReputationWatchBarTextureMid2:SetWidth(width-28);

	local numDivisions;
	if (appliedOptions) then
		numDivisions = appliedOptions.repBarNumDivisions or defDivisions;
	else
		numDivisions = defDivisions;
	end
	local divWidth = width / numDivisions;
	local xpos = divWidth - 4.5;
	for i=1, numDivisions-1 do
		local texture = _G["CT_BottomBar_ReputationWatchBarDiv" .. i];
		if (not texture) then
			texture = CT_BottomBar_ReputationWatchBar_CreateDivisionTexture(i);
		end
		local xalign = floor(xpos);
		texture:SetPoint("LEFT", xalign, divOffsetY);
		xpos = xpos + divWidth;
	end		

	CT_BottomBar_ReputationWatchStatusBar:SetWidth(width);
	CT_BottomBar_ReputationWatchBar:SetWidth(width);
end

local function CT_BottomBar_ReputationWatchBar_CreateFrames()
	local repBar, statBar, tx, overlayFrame, barText;

	repBar = CreateFrame("Frame", "CT_BottomBar_ReputationWatchBar", UIParent);
	repBar:SetWidth(defBarWidth);
	repBar:SetHeight(11);
	repBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
	repBar:EnableMouse(true);
	repBar:Hide();

	statBar = CreateFrame("StatusBar", "CT_BottomBar_ReputationWatchStatusBar", repBar);
	statBar:SetWidth(defBarWidth);
	statBar:SetHeight(8);
	statBar:SetPoint("TOP", repBar, "TOP", 0, -3);
	statBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	statBar:SetStatusBarColor(0.58, 0.0, 0.55);
	-- statBar:SetDrawLayer("ARTWORK");

	-- Border texture with a sublevel of -1 (below division textures which are at sublevel 0).
	tx = statBar:CreateTexture("CT_BottomBar_ReputationWatchBarTextureLeftCap1",  "OVERLAY", nil, -1);
	tx = statBar:CreateTexture("CT_BottomBar_ReputationWatchBarTextureRightCap1", "OVERLAY", nil, -1);
	tx = statBar:CreateTexture("CT_BottomBar_ReputationWatchBarTextureMid1",      "OVERLAY", nil, -1);

	-- Border texture with a sublevel of 1 (above division textures which are at sublevel 0).
	tx = statBar:CreateTexture("CT_BottomBar_ReputationWatchBarTextureLeftCap2",  "OVERLAY", nil,  1);
	tx = statBar:CreateTexture("CT_BottomBar_ReputationWatchBarTextureRightCap2", "OVERLAY", nil,  1);
	tx = statBar:CreateTexture("CT_BottomBar_ReputationWatchBarTextureMid2",      "OVERLAY", nil,  1);

	tx = statBar:CreateTexture("CT_BottomBar_ReputationWatchStatusBarBackground", "BACKGROUND");
	tx:SetColorTexture(0, 0, 0, 0.5);
	tx:SetAllPoints();

	overlayFrame = CreateFrame("Frame", "CT_BottomBar_ReputationWatchBarOverlayFrame", repBar);
	overlayFrame:SetFrameStrata("DIALOG");
	overlayFrame:SetAllPoints();

	barText = overlayFrame:CreateFontString("CT_BottomBar_ReputationWatchStatusBarText", "ARTWORK", "TextStatusBarText");
	barText:SetPoint("CENTER", overlayFrame, "CENTER", 0, 3);
	barText:Hide();

	repBar:SetScript("OnEvent",
		function(self, event, ...)
			local arg1, arg2 = ...;
			if( event == "UPDATE_FACTION" ) then
				(ReputationWatchBar_UpdateMaxLevel or ReputationWatchBar_Update)();  -- classic vs cata
			elseif( event == "PLAYER_LEVEL_UP" or event == "ENABLE_XP_GAIN" or event == "DISABLE_XP_GAIN" ) then
				(ReputationWatchBar_UpdateMaxLevel or ReputationWatchBar_Update)(arg1);  -- classic vs cata
				UIParent_ManageFramePositions()
			elseif( event == "CVAR_UPDATE" and arg1 == "XP_BAR_TEXT" ) then
				if( arg2 == "1" ) then
					CT_BottomBar_ShowWatchedReputationBarText("lock");
				else
					CT_BottomBar_HideWatchedReputationBarText("unlock");
				end
			end
		end
	);

	repBar:SetScript("OnShow",
		function(self)
			if ( GetCVar("xpBarText") == "1" ) then
				CT_BottomBar_ShowWatchedReputationBarText("lock");
			end
			UIParent_ManageFramePositions();
		end
	);

	repBar:SetScript("OnHide",
		function(self)
			UIParent_ManageFramePositions();
		end
	);

	repBar:SetScript("OnEnter",
		function(self)
			CT_BottomBar_ReputationWatchStatusBarText:Show();
		end
	);

	repBar:SetScript("OnLeave",
		function(self)
			if(not CT_BottomBar_ReputationWatchBar.textLocked) then
				CT_BottomBar_ReputationWatchStatusBarText:Hide();
			end
		end
	);

	repBar:RegisterEvent("UPDATE_FACTION");
	repBar:RegisterEvent("PLAYER_LEVEL_UP");
	repBar:RegisterEvent("ENABLE_XP_GAIN");
	repBar:RegisterEvent("DISABLE_XP_GAIN");
	repBar:RegisterEvent("CVAR_UPDATE");

	repBar:Hide();
end

--------------------------------------------
-- Reputation Bar

local function addon_isDisabled()
	local ctRepBar = module.ctRepBar;
	if (ctRepBar) then
		return ctRepBar.isDisabled;
	else
		return true;
	end
end

function module:CT_BottomBar_RepBar_SetWidth(width)
	local newWidth = width or appliedOptions.repBarWidth or defBarWidth;
	CT_BottomBar_RepBar_WatchBarFrame:SetWidth(newWidth);
	if (showingRepOnExp) then
		newWidth = module:CT_BottomBar_ExpBar_GetWidth(true) or defBarWidth;
	end
	CT_BottomBar_ReputationWatchBar_SetWidth(newWidth);
end

function module:CT_BottomBar_RepBar_Configure()
	CT_BottomBar_ReputationWatchBar_Configure();
	module:CT_BottomBar_RepBar_SetWidth();
end

local function addon_AnchorRepToRep(self)
	-- Anchor the reputation bar to the reputation bar's drag frame.
	-- self == rep bar object
	local objRep = CT_BottomBar_ReputationWatchBar;
	local objPlace = self.watchBarFrame;

	setparent(objRep, self.frame);
	objRep:EnableMouse(true);

	-- Clear the points for the guide frame, CT_BottomBar_ReputationWatchBar, and the place holder rep watch bar.
	self.helperFrame:ClearAllPoints();
	objRep:ClearAllPoints();
	objPlace:ClearAllPoints();

	-- Anchor the guide frame around the CT_BottomBar_ReputationWatchBar.
	self.helperFrame:SetPoint("TOPLEFT", objRep, 0, 0);
	self.helperFrame:SetPoint("BOTTOMRIGHT", objRep);

	-- Anchor the CT_BottomBar_ReputationWatchBar to the reputation bar's drag frame.
	objRep:SetPoint("BOTTOMLEFT", self.frame, 0, 0.5);
end

local function addon_AnchorRepToExp(self)
	-- Anchor the reputation bar to the experience bar's drag frame.
	-- self == rep bar object
	local objRep = CT_BottomBar_ReputationWatchBar;
	local objPlace = self.watchBarFrame;

	setparent(objRep, self.frame);
	objRep:EnableMouse(true);

	-- Clear the points for the guide frame, CT_BottomBar_ReputationWatchBar, and the place holder rep watch bar.
	self.helperFrame:ClearAllPoints();
	objRep:ClearAllPoints();
	objPlace:ClearAllPoints();

	-- Anchor the guide frame around the place holder rep watch bar.
	self.helperFrame:SetPoint("TOPLEFT", objPlace, 0, 0);
	self.helperFrame:SetPoint("BOTTOMRIGHT", objPlace);

	-- Anchor the place holder rep watch bar to the drag frame.
	objPlace:SetPoint("BOTTOMLEFT", self.frame, 0, 0);

	-- Anchor the CT_BottomBar_ReputationWatchBar to the experience bar's drag frame.
	objRep:SetPoint("BOTTOMLEFT", module.ctExpBar.frame, 0, 3);
end

local function addon_ShowRepBarOnExpBar()
	-- Show the reputation bar instead of the experience bar.

	showingRepOnExp = true;

	CT_BottomBar_ReputationWatchStatusBar:SetHeight(11);
	CT_BottomBar_ReputationWatchStatusBarText:SetPoint("CENTER", CT_BottomBar_ReputationWatchBarOverlayFrame, "CENTER", 0, -2);

	addon_AnchorRepToExp(module.ctRepBar);

	module:CT_BottomBar_RepBar_Configure();

	CT_BottomBar_MainMenuExpBar.pauseUpdates = true;
	CT_BottomBar_MainMenuExpBar:Hide();

	CT_BottomBar_ExhaustionTick:Hide();
end

local function addon_ShowRepBarSeparate()
	-- Show the reputation bar separate from the the experience bar.

	showingRepOnExp = false;

	CT_BottomBar_ReputationWatchStatusBar:SetHeight(8);
	CT_BottomBar_ReputationWatchStatusBarText:SetPoint("CENTER", CT_BottomBar_ReputationWatchBarOverlayFrame, "CENTER", 0, 0);

	addon_AnchorRepToRep(module.ctRepBar);

	module:CT_BottomBar_RepBar_Configure();

	CT_BottomBar_MainMenuExpBar.pauseUpdates = nil;
	CT_BottomBar_MainMenuExpBar:Show();
end

local function addon_Modified_ReputationWatchBar_Update(hideReputationBar, hideExperienceBar, repBarCoverExpBar, repBarHideNoRep, expBarShowMaxLevelBar)
	local name, reaction, min, max, value, factionID = GetWatchedFactionInfo();
	if (not name) then
		-- Not monitoring a faction.
		CT_BottomBar_ReputationWatchStatusBar:SetMinMaxValues(0, 0);
		CT_BottomBar_ReputationWatchStatusBar:SetValue(0);
		CT_BottomBar_ReputationWatchStatusBarText:SetText("");
		CT_BottomBar_ReputationWatchBar.factionID = nil;
		CT_BottomBar_ReputationWatchBar.friendshipID = nil;
	else
		local colorIndex = reaction;
		-- If it's a different faction, save possible friendship id
		if ( CT_BottomBar_ReputationWatchBar.factionID ~= factionID ) then
			CT_BottomBar_ReputationWatchBar.factionID = factionID;
			CT_BottomBar_ReputationWatchBar.friendshipID = nil; -- GetFriendshipReputation(factionID);
		end
		local isCappedFriendship;
		-- Do something different for friendships
		if ( CT_BottomBar_ReputationWatchBar.friendshipID ) then
			local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID);
			if ( nextFriendThreshold ) then
				min, max, value = friendThreshold, nextFriendThreshold, friendRep;
			else
				-- Max rank, make it look like a full bar
				min, max, value = 0, 1, 1;
				isCappedFriendship = true;
			end
			colorIndex = 5;		-- Always color friendships green
		end
		-- Normalize values
		max = max - min;
		value = value - min;
		min = 0;
		CT_BottomBar_ReputationWatchStatusBar:SetMinMaxValues(min, max);
		CT_BottomBar_ReputationWatchStatusBar:SetValue(value);
		if ( isCappedFriendship ) then
			CT_BottomBar_ReputationWatchStatusBarText:SetText(name);
		else
			CT_BottomBar_ReputationWatchStatusBarText:SetText(name .. " " .. value .. " / " .. max);
		end
		local color = FACTION_BAR_COLORS[colorIndex];
		CT_BottomBar_ReputationWatchStatusBar:SetStatusBarColor(color.r, color.g, color.b);
	end

	CT_BottomBar_ReputationWatchStatusBar:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel()-1);

	if (repBarCoverExpBar) then
		-- Show the reputation bar on the experience bar.
		addon_ShowRepBarOnExpBar();
	else
		-- Show the reputation bar separate from the the experience bar.
		addon_ShowRepBarSeparate();
	end

	-- Default ui
	-- 	- when not at max level
	-- 		- enabling "show as experience bar" displays the rep bar above the exp bar
	--		- else it hides rep bar and only shows exp bar
	-- 	- when at max level
	--		- enabling "show as experience bar" replaces the exp bar with the rep bar.
	--		- else it hides the exp bar and shows the max level bar.
	
	-- Hide/show the CT bars.
	local hideExp, hideRep, hideMax;
	if (repBarCoverExpBar) then
		hideExp = true;
	else
		if (hideExperienceBar) then
			hideExp = true;
		else
			hideExp = false;
		end
	end
	if (hideReputationBar) then
		hideRep = true;
	else
		if (repBarHideNoRep and not name) then
			hideRep = true;
		else
			hideRep = false;
		end
	end
	if (expBarShowMaxLevelBar and hideExp and hideRep) then
		hideMax = false;
	else
		hideMax = true;
	end

	-- Hide/show the default Blizzard bars based on the CT options.
	-- This will allow some of Blizzard's bars to get repositioned
	-- the same way they do when not using CT. UIParent_ManageFramePositions()
	-- will adjust blizzard action bars, open bags, etc based on the
	-- visibility of the exp and rep bars.
	-- The default UI expects the exp bar to always be visible (or the rep bar
	-- superimposed on the exp bar).
	local hideDefExp, hideDefMax, hideDefRep;
	if (not hideMax) then
		-- Due to the previous code, hideMax can only be false if hideExp and hideRep are both true.
		-- So show Blizz max only.
		hideDefExp = true;
		hideDefMax = false;
		hideDefRep = true;
	else
		-- Hiding max
		if (hideExp) then
			if (hideRep) then
				-- Hiding CT max and exp and rep, so show Blizz exp
				hideDefExp = false;
				hideDefMax = true;
				hideDefRep = true;
			else
				-- Hiding CT max and exp, Showing CT rep, so show Blizz exp
				hideDefExp = false;
				hideDefMax = true;
				hideDefRep = true;
			end
		else
			if (hideRep) then
				-- Hiding CT max and rep, Showing CT exp, so show Blizz exp
				hideDefExp = false;
				hideDefMax = true;
				hideDefRep = true;
			else
				-- Hiding CT max, Showing CT exp and rep, so show Blizz exp and rep
				hideDefExp = false;
				hideDefMax = true;
				hideDefRep = false;
			end
		end
	end

	---- I think it is safe to hide/show frames that Blizzard is animating,
	---- but trying to SetParent() or SetPoint() them can cause positioning
	---- issues with the frame or its children.
	--if (module:CT_BottomBar_ExpBar_isAnimFinished()) then
	--if (not module:isBlizzardAnimating()) then
		if (hideDefRep) then
			ReputationWatchBar:Hide();
		else
			ReputationWatchBar:Show();
		end
		if (hideDefExp) then
			MainMenuExpBar.pauseUpdates = true;
			MainMenuExpBar:Hide();
		else
			MainMenuExpBar.pauseUpdates = false;
			MainMenuExpBar:Show();
		end
		if (hideDefMax) then
			MainMenuBarMaxLevelBar:Hide();
		else
			MainMenuBarMaxLevelBar:Show();
		end
	--end

	-- Hide or show the CT rep bar.
	if (hideRep) then
		CT_BottomBar_ReputationWatchBar:Hide();
	else
		CT_BottomBar_ReputationWatchBar:Show();
	end

	-- Hide or show the CT exp bar.
	if (hideExp) then
		CT_BottomBar_MainMenuExpBar.pauseUpdates = true;
		CT_BottomBar_MainMenuExpBar:Hide();
	else
		CT_BottomBar_MainMenuExpBar.pauseUpdates = nil;
		CT_BottomBar_MainMenuExpBar:Show();
	end

	-- Hide or show the CT max level exp bar.
	if (hideMax) then
		CT_BottomBar_MainMenuBarMaxLevelBar:Hide();
	else
		CT_BottomBar_MainMenuBarMaxLevelBar:Show();
	end

	-- Call this function will let Blizzard shift some of their frames to account
	-- for the visibility (or lack of visibility) of the experience and rep bars.
	UIParent_ManageFramePositions();

	-- Update the experience bar.
	module.CT_BottomBar_MainMenuExpBar_Update(module.ctExpBar);

	module.ctRepBar:updateDragVisibility(nil);
	module.ctExpBar:updateDragVisibility(nil);
end

local function addon_Update(self)
	-- self == rep bar object
	if (isBusy()) then
		setDelayedUpdate(1);
		return;
	end

	local hideReputationBar, repBarCoverExpBar, repBarHideNoRep, expBarShowMaxLevelBar;
	local hideExperienceBar = module:CT_BottomBar_ExpBar_GetHideExperienceBar();

	local specialType = module:CT_BottomBar_ExpBar_GetspecialType();
	local canShowExpOnSpecial = module:CT_BottomBar_ExpBar_CanShowExpOnSpecialUI(specialType)

	if (canShowExpOnSpecial and not hideExperienceBar) then
		-- Exp bar is to be shown on a special UI (vehicle/override) frame.
		local newRepHideState;
		if (appliedOptions["Reputation Bar"]) then
			-- User always wants the rep bar hidden.
			newRepHideState = true;
		else
			if (appliedOptions.repBarCoverExpBar) then
				-- User was covering the exp bar with the rep bar.
				-- so don't show the rep bar while player has the vehicle/override frame.
				newRepHideState = true;
			else
				-- The rep bar is being displayed separately.
				-- -- Don't hide the rep bar while player has the vehicle/override frame.
				-- newRepHideState = false;
				newRepHideState = true;  -- hide the rep bar
			end
		end
		hideReputationBar = newRepHideState;
		repBarCoverExpBar = false;
		repBarHideNoRep = appliedOptions.repBarHideNoRep;
		expBarShowMaxLevelBar = false;
	else
		-- Exp bar is not to be shown on a special UI (vehicle/override) frame.
		hideReputationBar = appliedOptions["Reputation Bar"];
		repBarCoverExpBar = appliedOptions.repBarCoverExpBar;
		repBarHideNoRep = appliedOptions.repBarHideNoRep;
		expBarShowMaxLevelBar = appliedOptions.expBarShowMaxLevelBar;
	end
	addon_Modified_ReputationWatchBar_Update(hideReputationBar, hideExperienceBar, repBarCoverExpBar, repBarHideNoRep, expBarShowMaxLevelBar);
end

local function addon_updateVisibility()
	-- This will get called at the end of addon:updateVisibility().
	-- Call Blizzard's function that updates the reputation and exp bars.
	(ReputationWatchBar_UpdateMaxLevel or ReputationWatchBar_Update)();
end

local function addon_OnAnimFinished(self)
	-- Called after the Main Menu Bar and Override Action Bars
	-- have finished animating.
	-- self == rep bar object
	self:update();
end

--------------------------------------------
-- Hooks

local function addon_Hooked_ReputationWatchBar_Update(newLevel)
	-- hooksecurefunc of ReputationWatchBar_UpdateMaxLevel() in ReputationFrame.lua; or ReputationWatchBar_Update() in Cataclysm Clasic
	-- We don't need the newLevel parameter.
	if (addon_isDisabled()) then
		return;
	end
	addon_Update(module.ctRepBar);
end

local function addon_Hooked_OverrideActionBar_UpdateXpBar(newLevel)
	if (addon_isDisabled()) then
		return;
	end
	addon_Update(module.ctRepBar);
end

local function addon_Hooked_PetBattleFrame_UpdateXpBar(self)
	if (addon_isDisabled()) then
		return;
	end
	addon_Update(module.ctRepBar);
end

--------------------------------------------
-- Enable, disable, initialize, register.

local function addon_Enable(self)
	module:CT_BottomBar_RepBar_Configure();
end

local function addon_Init(self)
	-- Initialization
	-- self == rep bar object

	appliedOptions = module.appliedOptions;

	ctAddon = self;
	module.ctRepBar = self;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	setparent = frame.SetParent;

	frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_WatchBarFrame");
	self.watchBarFrame = frame;

	frame:SetWidth(CT_BottomBar_ReputationWatchBar:GetWidth());
	frame:SetHeight(CT_BottomBar_ReputationWatchBar:GetHeight());
	frame:SetParent(self.frame);

	-- (from ReputationFrame.lua)
	if ReputationWatchBar_UpdateMaxLevel then
		hooksecurefunc("ReputationWatchBar_UpdateMaxLevel", addon_Hooked_ReputationWatchBar_Update);
	else
		hooksecurefunc("ReputationWatchBar_Update", addon_Hooked_ReputationWatchBar_Update);
	end
	
--	hooksecurefunc("VehicleMenuBar_MoveMicroButtons", addon_Hooked_VehicleMenuBar_MoveMicroButtons);
--	hooksecurefunc("ActionBar_AnimTransitionFinished", addon_Hooked_AnimTransitionFinished);

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Reputation Bar",  -- option name
		"RepBar",  -- used in frame names
		module.text["CT_BottomBar/Options/RepBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/RepBar"],  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -512, 52 },
		{ -- settings
			orientation = "ACROSS",
			usedOnVehicleUI = true,  -- Set to true even though rep bar not shown on vehicle UI bar.
			usedOnOverrideUI = true,  -- Set to true even though rep bar not shown on override UI bar.
			usedOnPetBattleUI = true,  -- Set to true even though rep bar not shown on pet battle UI bar.
			optionsIndentBarName = true,  -- indent bar name in the list of bars on the options window
			updateVisibility = addon_updateVisibility,
			OnAnimFinished = addon_OnAnimFinished,
		},
		addon_Init,
		nil,  -- no PostInit function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		nil,  -- no disable function
		"helperFrame",
		CT_BottomBar_ReputationWatchBar
	);
end

if (not StatusTrackingBarMixin) then
	CT_BottomBar_ReputationWatchBar_CreateFrames();
	module.loadedAddons["Reputation Bar"] = addon_Register;
end