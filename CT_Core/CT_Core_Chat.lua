------------------------------------------------
--                  CT_Core                   --
--                                            --
-- Core addon for doing basic and popular     --
-- things in an intuitive way.                --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local _G = getfenv(0);
local module = _G.CT_Core;

--------------------------------------------
-- Hide the friends button.

local chgFriendsButtonHide;

local function setFriendsButton(showButton)
	local button = QuickJoinToastButton;
	if (button and button.Show and button.Hide) then -- Made safe for Retail
		if (showButton) then
			button:Show();
		else
			button:Hide();
		end
	end
end

local function updateFriendsButtonHide()
	local hideButton = module:getOption("friendsMicroButton");
	if (not hideButton) then
		if (chgFriendsButtonHide) then
			chgFriendsButtonHide = false;
			setFriendsButton(true);
		end
	else
		setFriendsButton(false);
		chgFriendsButtonHide = true;
	end
end

--------------------------------------------
-- Hide the chat buttons (conversation, minimize, up, down, bottom).

local chgChatButtonsHide;
local func_updateChatButtonsHide;

local function setChatFrameButtons(chatFrame, showButtons)
	local chatFrameName = chatFrame:GetName();
	if (chatFrameName) then
		local buttonFrame = _G[chatFrameName .. "ButtonFrame"];
		local channelButton = ChatFrameChannelButton;
		if (buttonFrame and buttonFrame.Show and buttonFrame.Hide) then -- Made safe for Retail
			if (showButtons) then
				buttonFrame:Show();
				if (channelButton and channelButton.Show) then
					channelButton:Show();
				end
			else
				buttonFrame:Hide();
				if (channelButton and channelButton.Hide) then
					channelButton:Hide();
				end
			end
			if (not buttonFrame.ctOnShow) then
				buttonFrame.ctOnShow = true;
				buttonFrame:HookScript("OnShow", func_updateChatButtonsHide);
			end
		end
		if (channelButton and channelButton.Show and channelButton.Hide) then -- Made safe for Retail
			if (showButtons) then
				channelButton:Show();
			else
				channelButton:Hide();
			end
			if (not channelButton.ctOnShow) then
				channelButton.ctOnShow = true;
				channelButton:HookScript("OnShow", func_updateChatButtonsHide);
			end		
		end
	end
end

local function setChatButtons(showButtons)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if (chatFrame) then
			setChatFrameButtons(chatFrame, showButtons);
		end
	end
end

local function updateChatButtonsHide()
	local hideButtons = module:getOption("chatArrows");
	if (not hideButtons) then
		if (chgChatButtonsHide) then
			chgChatButtonsHide = false;
			setChatButtons(true);
		end
	else
		setChatButtons(false);
		chgChatButtonsHide = true;
	end
end

func_updateChatButtonsHide = updateChatButtonsHide;

--------------------------------------------
-- Hide the chat menu button.

local chgChatMenuButtonHide;
local hookedChatMenuButtonOnShow;
local func_updateChatMenuButtonHide;

local function setChatMenuButton(showButton)
	local button = ChatFrameMenuButton;
	if (button and button.Show and button.Hide) then -- Made safe for Retail
		if (showButton) then
			button:Show();
		else
			button:Hide();
		end
		if (not hookedChatMenuButtonOnShow) then
			hookedChatMenuButtonOnShow = true;
			ChatFrameMenuButton:HookScript("OnShow", func_updateChatMenuButtonHide);
		end
	end
end

local function updateChatMenuButtonHide()
	local hideButton = module:getOption("chatArrows");
	if (not hideButton) then
		if (chgChatMenuButtonHide) then
			chgChatMenuButtonHide = false;
			setChatMenuButton(true);
		end
	else
		setChatMenuButton(false);
		chgChatMenuButtonHide = true;
	end
end

func_updateChatMenuButtonHide = updateChatMenuButtonHide;

--------------------------------------------
-- Chat scrolling (using shift, control keys).

hooksecurefunc("FloatingChatFrame_OnMouseScroll",
	function(self, delta)
		if ( not module:getOption("chatScrolling") ) then
			return;
		end
		if ( delta and delta > 0 ) then
			if ( IsShiftKeyDown() ) then
				self:ScrollToTop();
			elseif ( IsControlKeyDown() ) then
				self:ScrollDown();
				self:PageUp();
			end
		else
			if ( IsShiftKeyDown() ) then
				self:ScrollToBottom();
			elseif ( IsControlKeyDown() ) then
				self:ScrollUp();
				self:PageDown();
			end
		end
	end
);

local function updateChatScrolling()
end

--------------------------------------------
-- Move input box to top of chat frame.

local chgChatEditTop;

local function setChatFrameEditTop(chatFrame, showAtTop)
	local pos = module:getOption("chatEditPosition") or 0;
	local chatFrameName = chatFrame:GetName();
	if (chatFrameName) then
		local editBox = _G[chatFrameName .. "EditBox"];
		if (editBox) then
			if (showAtTop) then
				local yoffset;
				if (IsCombatLog(chatFrame)) then
					yoffset = 4 + pos;
					if (pos > 0) then
						yoffset = yoffset + 26;
					end
				else
					yoffset = 6 + pos;
				end
				editBox:ClearAllPoints();
				editBox:SetPoint("TOPLEFT", chatFrameName, "TOPLEFT", -5, yoffset);
				editBox:SetPoint("TOPRIGHT", chatFrameName, "TOPRIGHT", 5, yoffset);
			else
				editBox:ClearAllPoints();
				editBox:SetPoint("TOPLEFT", chatFrameName, "BOTTOMLEFT", -5, -2);
				editBox:SetPoint("TOPRIGHT", chatFrameName, "BOTTOMRIGHT", 5, -2);
			end
		end
	end
end

local function setChatEditTop(showAtTop)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if (chatFrame) then
			setChatFrameEditTop(chatFrame, showAtTop);
		end
	end
end

local function updateChatEditTop()
	local showAtTop = module:getOption("chatEditMove");
	if (not showAtTop) then
		if (chgChatEditTop) then
			chgChatEditTop = false;
			setChatEditTop(false);
		end
	else
		setChatEditTop(true);
		chgChatEditTop = true;
	end
end

--------------------------------------------
-- Chat text fading: Time visible

local chgChatTimeVisible;

local function setChatFrameTimeVisible(chatFrame, seconds)
	if chatFrame.SetTimeVisible then chatFrame:SetTimeVisible(seconds); end
end

local function setChatTimeVisible(seconds)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if (chatFrame) then
			setChatFrameTimeVisible(chatFrame, seconds);
		end
	end
end

local function updateChatTimeVisible()
	local seconds = module:getOption("chatTimeVisible");
	if (seconds and seconds >= 0) then
		setChatTimeVisible(seconds);
		chgChatTimeVisible = true;
	else
		if (chgChatTimeVisible) then
			chgChatTimeVisible = false;
			setChatTimeVisible(120);
		end
	end
end

--------------------------------------------
-- Chat text fading: Fade duration

local chgChatFadeDuration;

local function setChatFrameFadeDuration(chatFrame, seconds)
	if chatFrame.SetFadeDuration then chatFrame:SetFadeDuration(seconds); end
end

local function setChatFadeDuration(seconds)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if (chatFrame) then
			setChatFrameFadeDuration(chatFrame, seconds);
		end
	end
end

local function updateChatFadeDuration()
	local seconds = module:getOption("chatFadeDuration");
	if (seconds and seconds >= 0) then
		setChatFadeDuration(seconds);
		chgChatFadeDuration = true;
	else
		if (chgChatFadeDuration) then
			chgChatFadeDuration = false;
			setChatFadeDuration(3);
		end
	end
end

--------------------------------------------
-- Chat text fading: Disable fading

local chgChatFadingDisable;

local function setChatFrameFading(chatFrame, enableFading)
	if chatFrame.SetFading then chatFrame:SetFading(enableFading); end
end

local function setChatFading(enableFading)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if (chatFrame) then
			setChatFrameFading(chatFrame, enableFading);
		end
	end
end

local function updateChatFadingDisable()
	local disableFading = module:getOption("chatDisableFading");
	if (disableFading) then
		setChatFading(false);
		chgChatFadingDisable = true;
	else
		if (chgChatFadingDisable) then
			chgChatFadingDisable = false;
			setChatFading(true);
		end
	end
end

--------------------------------------------
-- Chat frame clamping

local chgChatClamping;

local function setChatFrameClamping(chatFrame, enableClamping, useInsets)
	chatFrame:SetClampedToScreen(enableClamping);
	if (useInsets) then
		if (chatFrame == ChatFrame1) then
			chatFrame:SetClampRectInsets(-35, 35, 38, -50);
		else
			chatFrame:SetClampRectInsets(-35, 35, 26, -50);
		end
	else
		chatFrame:SetClampRectInsets(1, -1, 26, 0);
	end
end

local function setChatClamping(enableClamping, useInsets)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if (chatFrame) then
			setChatFrameClamping(chatFrame, enableClamping, useInsets);
		end
	end
end

local function updateChatClamping()
	local clampMode = module:getOption("chatClamping") or 1;
	if (clampMode == 2) then
		setChatClamping(true, false);
		chgChatClamping = true;
	elseif (clampMode == 3) then
		setChatClamping(false, false);
		chgChatClamping = true;
	else
		if (chgChatClamping) then
			chgChatClamping = false;
			setChatClamping(true, true);
		end
	end
end

--------------------------------------------
-- Chat Tab Opacity

module.optChatTabOpacity = {
	{
		heading = "Mouse not over chat frame",
		sliders = {
			{option = "chatTabNormalNoMouseAlpha",   default = -0.01, label = "Normal",   varname = "CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA",   gameDefault = 0.2},
			{option = "chatTabSelectedNoMouseAlpha", default = -0.01, label = "Selected", varname = "CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA", gameDefault = 0.4},
			{option = "chatTabAlertingNoMouseAlpha", default = -0.01, label = "Alerting", varname = "CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA", gameDefault = 1.0},
		},
	},
	{
		heading = "Mouse over chat frame",
		sliders = {
			{option = "chatTabNormalMouseOverAlpha",   default = -0.01, label = "Normal",   varname = "CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA",   gameDefault = 0.6},
			{option = "chatTabSelectedMouseOverAlpha", default = -0.01, label = "Selected", varname = "CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA", gameDefault = 1.0},
			{option = "chatTabAlertingMouseOverAlpha", default = -0.01, label = "Alerting", varname = "CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA", gameDefault = 1.0},
		},
	},
};

local chgChatTabAlpha = {};

local function setChatTabAlpha(tbl, opacity)
	_G[tbl.varname] = opacity;
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if (chatFrame and FCFTab_UpdateAlpha) then
			FCFTab_UpdateAlpha(chatFrame);
		end
	end
end

local function updateChatTabAlpha(tbl)
	local opacity = module:getOption(tbl.option);
	if (not opacity) then
		opacity = tbl.default;
	end
	if (opacity and opacity < 0) then
		if (chgChatTabAlpha[tbl.option]) then
			chgChatTabAlpha[tbl.option] = false;
			setChatTabAlpha(tbl, tbl.gameDefault);
		end
	else
		setChatTabAlpha(tbl, opacity or tbl.gameDefault);
		chgChatTabAlpha[tbl.option] = true;
	end
end

local function updateChatTabAlphas()
	for i, optTable in ipairs(module.optChatTabOpacity) do
		for j, tbl in ipairs(optTable.sliders) do
			updateChatTabAlpha(tbl);
		end
	end
end

--------------------------------------------
-- Chat frame resize buttons

local chgChatResizeButton = {};

local function setChatFrameResizeButton(chatFrame, buttonNum, enableButton)
	if (not chatFrame.ctResizeButtons) then
		chatFrame.ctResizeButtons = {};
	end
	local btn;
	if (buttonNum == 4) then
		btn = chatFrame.resizeButton;
		if (not btn) then
			local chatFrameName = chatFrame:GetName();
			if (chatFrameName) then
				btn = _G[chatFrameName .. "ResizeButton"];
			end
		end
	else
		btn = chatFrame.ctResizeButtons[buttonNum];
	end
	if (btn and btn.Show and btn.Hide) then -- Made safe for Retail
		if ( chatFrame.isUninteractable or chatFrame.isLocked ) then
			btn:Hide();
		else
			if (enableButton) then
				btn:Show();
			else
				btn:Hide();
			end
		end
	end
end

local function setChatResizeButton(buttonNum, enableButton)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if chatFrame and not chatFrame.OnEditModeEnter then
			setChatFrameResizeButton(chatFrame, buttonNum, enableButton);
		end
	end
end

local function updateChatResizeButton(buttonNum)
	local enableButton = module:getOption("chatResizeEnabled" .. buttonNum);
	if (buttonNum == 4) then
		if (enableButton or enableButton == nil) then
			if (chgChatResizeButton[buttonNum]) then
				chgChatResizeButton[buttonNum] = false;
				setChatResizeButton(buttonNum, true);
			end
		else
			setChatResizeButton(buttonNum, false);
			chgChatResizeButton[buttonNum] = true;
		end
	else
		if (enableButton) then
			setChatResizeButton(buttonNum, true);
			chgChatResizeButton[buttonNum] = true;
		else
			if (chgChatResizeButton[buttonNum]) then
				chgChatResizeButton[buttonNum] = false;
				setChatResizeButton(buttonNum, false);
			end
		end
	end
end

local function updateChatResizeButtons()
	if module:getGameVersion() >= 10 then return end -- Disabled for Retail since Edit Mode handles this entirely
	for buttonNum = 1, 4 do
		updateChatResizeButton(buttonNum);
	end
end

local s2 = sqrt(2);
local cos, sin, rad = math.cos, math.sin, math.rad;
local function CalculateCorner(angle)
	local r = rad(angle);
	return 0.5 + cos(r) / s2, 0.5 + sin(r) / s2;
end
local function RotateTexture(texture, angle)
	if not texture then return end
	local LRx, LRy = CalculateCorner(angle + 45);
	local LLx, LLy = CalculateCorner(angle + 135);
	local ULx, ULy = CalculateCorner(angle + 225);
	local URx, URy = CalculateCorner(angle - 45);
	texture:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
end

local function assignChatFrameResizeDefaultTexture(btn, buttonNum)
	local tx;
	btn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
	tx = btn:GetNormalTexture(); if tx then RotateTexture(tx, 90 * buttonNum); end
	btn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
	tx = btn:GetHighlightTexture(); if tx then RotateTexture(tx, 90 * buttonNum); end
	btn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
	tx = btn:GetPushedTexture(); if tx then RotateTexture(tx, 90 * buttonNum); end
end

local function setChatFrameResizeMouseover(chatFrame, showOnMouseover)
	if (not chatFrame.ctResizeButtons) then
		chatFrame.ctResizeButtons = {};
	end
	local btn;
	for buttonNum = 1, 4 do
		if (buttonNum == 4) then
			btn = chatFrame.resizeButton;
			if (not btn) then
				local chatFrameName = chatFrame:GetName();
				if (chatFrameName) then btn = _G[chatFrameName .. "ResizeButton"]; end
			end
		else
			btn = chatFrame.ctResizeButtons[buttonNum];
		end
		if btn and btn.GetNormalTexture then
			assignChatFrameResizeDefaultTexture(btn, buttonNum)
			local tex = btn:GetNormalTexture()
			if tex then tex:SetAlpha(showOnMouseover and not btn:IsMouseOver() and 0 or 1) end
		end
	end
end

local function setChatResizeMouseover(showOnMouseover)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if chatFrame and not chatFrame.OnEditModeEnter then
			setChatFrameResizeMouseover(chatFrame, showOnMouseover);
		end
	end
end

local function updateChatResizeMouseover()
	if module:getGameVersion() >= 10 then return end -- Disabled for Retail
	local showOnMouseover = module:getOption("chatResizeMouseover");
	if (showOnMouseover) then
		setChatResizeMouseover(true);
		chgChatResizeMouseover = true;
	else
		if (chgChatResizeMouseover) then
			chgChatResizeMouseover = false;
			setChatResizeMouseover(false);
		end
	end
end

local chatResizePoints = {"TOPRIGHT", "TOPLEFT", "BOTTOMLEFT"};

local function createChatFrameResizeButtons(chatFrame)
	if (module:getGameVersion() >= 10) then return false end -- Fully blocked in Retail to prevent UI lockups
	if (not chatFrame) then return; end
	local chatFrameName = chatFrame:GetName();
	if (not chatFrameName) then return; end
	if (not chatFrame.ctResizeButtons) then chatFrame.ctResizeButtons = {}; end
	local updated;
	for buttonNum = 1, 3 do
		if (not chatFrame.ctResizeButtons[buttonNum]) then
			local bg;
			local btn = CreateFrame("Button");
			btn:SetHeight(16); btn:SetWidth(16); btn:SetParent(chatFrame);
			bg = _G[chatFrameName .. "Background"];
			if (bg) then btn:SetPoint(chatResizePoints[buttonNum], bg, chatResizePoints[buttonNum], 0, 0); end
			local keepFadedIn;
			local function preventFadeOutDuringDrag()
				if (keepFadedIn) then
					chatFrame.mouseOutTime = 0;
					if ( not chatFrame.hasBeenFaded ) then FCF_FadeInChatFrame(chatFrame); end
					C_Timer.After(0.1, preventFadeOutDuringDrag);
				end
			end
			btn:SetScript("OnMouseDown", function(self)
				local chatFrame = self:GetParent();
				self:SetButtonState("PUSHED", true);
				if self:GetHighlightTexture() then self:GetHighlightTexture():Hide(); end
				chatFrame:StartSizing(chatResizePoints[buttonNum]);
				keepFadedIn = true;
				C_Timer.After(0.1, preventFadeOutDuringDrag);
			end);
			btn:SetScript("OnMouseUp", function(self)
				self:SetButtonState("NORMAL", false);
				if self:GetHighlightTexture() then self:GetHighlightTexture():Show(); end
				self:GetParent():StopMovingOrSizing();
				if FCF_SavePositionAndDimensions then FCF_SavePositionAndDimensions(self:GetParent()); end
				keepFadedIn = false;
			end);
			btn:Hide();
			chatFrame.ctResizeButtons[buttonNum] = btn;
			assignChatFrameResizeDefaultTexture(btn, buttonNum);
			updated = true;
		end
	end
	return updated;
end

local function createChatResizeButtons()
	if module:getGameVersion() >= 10 then return false end
	local updated;
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName]
		if chatFrame and not chatFrame.OnEditModeEnter then updated = createChatFrameResizeButtons(chatFrame) end
	end
	return updated
end

if (createChatResizeButtons()) then
	updateChatResizeButtons();
	updateChatResizeMouseover();
end

if FCF_SetLocked then
	hooksecurefunc("FCF_SetLocked", function(chatFrame, isLocked) updateChatResizeButtons(); end);
end
if FCF_SetUninteractable then
	hooksecurefunc("FCF_SetUninteractable", function(chatFrame, isUninteractable) updateChatResizeButtons(); end);
end

--------------------------------------------
-- Chat frame sticky chat types

module.chatStickyTypes = {
	{default = 1, chatType = "BATTLEGROUND", label = "Battleground"},
	{default = 1, chatType = "CHANNEL", label = "Channel"},
	{default = 1, chatType = "EMOTE", label = "Emote"},
	{default = 1, chatType = "GUILD", label = "Guild"},
	{default = 1, chatType = "OFFICER", label = "Officer"},
	{default = 1, chatType = "PARTY", label = "Party"},
	{default = 1, chatType = "RAID", label = "Raid"},
	{default = 1, chatType = "BN_CONVERSATION", label = "Real ID conversation"},
	{default = 1, chatType = "BN_WHISPER", label = "Real ID whisper"},
	{default = 1, chatType = "SAY", label = "Say"},
	{default = 1, chatType = "WHISPER", label = "Whisper"},
	{default = 1, chatType = "YELL", label = "Yell"},
};

for i = #module.chatStickyTypes, 1, -1 do
	if not ChatTypeInfo[module.chatStickyTypes[i].chatType] then
		tremove(module.chatStickyTypes, i)
	end
end

local function setChatStickyFlag(chatType, stickyMode)
	if (not ChatTypeInfo[chatType]) then return end
	if (stickyMode ~= 1) then stickyMode = 0; end
	ChatTypeInfo[chatType].sticky = stickyMode;
end

local function updateChatStickyFlag(stickyInfo)
	local chatType = stickyInfo.chatType;
	local stickyMode = module:getOption("chatSticky" .. chatType);
	if (stickyMode == nil) then stickyMode = stickyInfo.default; end
	if (stickyMode) then setChatStickyFlag(chatType, 1) else setChatStickyFlag(chatType, 0) end
end

local function updateChatStickyFlags()
	for i, stickyInfo in ipairs(module.chatStickyTypes) do updateChatStickyFlag(stickyInfo); end
end

--------------------------------------------
-- Override chat frame resize limits.

local chgChatNoResizeLimits;

local function setChatFrameNoResizeLimits(chatFrame, hasNoLimits)
	local width, height;
	local minWidth, minHeight, maxWidth, maxHeight;

	local defMinWidth = CHAT_FRAME_MIN_WIDTH or 250;
	local defMinHeight = CHAT_FRAME_NORMAL_MIN_HEIGHT or 100;
	local defMinHeight2 = CHAT_FRAME_BIGGER_MIN_HEIGHT or 100;
	local defMaxWidth = 608;
	local defMaxHeight = 400;

	local ctMinWidth = 25;
	local ctMinHeight = 20;
	local ctMinHeight2 = ctMinHeight + (defMinHeight2 - defMinHeight);
	local ctMaxWidth = 6000;
	local ctMaxHeight = 6000;

	if (not chatFrame) then return end

	local chatType = chatFrame.chatType;
	if ( chatType and (chatType == "BN_CONVERSATION" or chatType == "BN_WHISPER") ) then
		if (hasNoLimits) then minWidth = ctMinWidth; minHeight = ctMinHeight2; maxWidth = ctMaxWidth; maxHeight = ctMaxHeight; else minWidth = defMinWidth; minHeight = defMinHeight2; maxWidth = defMaxWidth; maxHeight = defMaxHeight; end
	else
		if (hasNoLimits) then minWidth = ctMinWidth; minHeight = ctMinHeight; maxWidth = ctMaxWidth; maxHeight = ctMaxHeight; else minWidth = defMinWidth; minHeight = defMinHeight; maxWidth = defMaxWidth; maxHeight = defMaxHeight; end
	end

	if chatFrame.SetResizeBounds then
		chatFrame:SetResizeBounds(minWidth,minHeight,maxWidth,maxHeight)
	elseif chatFrame.SetMinResize and chatFrame.SetMaxResize then
		chatFrame:SetMinResize(minWidth, minHeight)
		chatFrame:SetMaxResize(maxWidth, maxHeight)
	end

	width = chatFrame:GetWidth(); height = chatFrame:GetHeight();
	if (width) then if (width < minWidth) then chatFrame:SetWidth(minWidth) elseif (width > maxWidth) then chatFrame:SetWidth(maxWidth) end end
	if (height) then if (height < minHeight) then chatFrame:SetHeight(minHeight) elseif (height > maxHeight) then chatFrame:SetHeight(maxHeight) end end
end

local function setChatNoResizeLimits(hasNoLimits)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local chatFrame = _G[chatFrameName];
		if (chatFrame) then setChatFrameNoResizeLimits(chatFrame, hasNoLimits); end
	end
end

local function updateChatNoResizeLimits()
	local hasNoLimits = module:getOption("chatMinMaxSize");
	if (hasNoLimits) then
		setChatNoResizeLimits(true); chgChatNoResizeLimits = true;
	else
		if (chgChatNoResizeLimits) then chgChatNoResizeLimits = false; setChatNoResizeLimits(false); end
	end
end

--------------------------------------------
-- Chat frame opacity

module.optChatFrameOpacity = {
	{ sliders = { {option = "chatFrameDefaultAlpha", default = -0.01, label = "Default", varname = "DEFAULT_CHATFRAME_ALPHA", gameDefault = 0.25} } },
};

local chgChatDefaultAlpha = {};

local function setChatDefaultAlpha(tbl, opacity)
	_G[tbl.varname] = opacity;
end

local function updateChatDefaultAlpha(tbl)
	local opacity = module:getOption(tbl.option);
	if (not opacity) then opacity = tbl.default; end
	if (opacity and opacity < 0) then
		if (chgChatDefaultAlpha[tbl.option]) then chgChatDefaultAlpha[tbl.option] = false; setChatDefaultAlpha(tbl, tbl.gameDefault); end
	else
		setChatDefaultAlpha(tbl, opacity or tbl.gameDefault); chgChatDefaultAlpha[tbl.option] = true;
	end
end

local function updateChatDefaultAlphas()
	for i, optTable in ipairs(module.optChatFrameOpacity) do for j, tbl in ipairs(optTable.sliders) do updateChatDefaultAlpha(tbl); end end
end

--------------------------------------------
-- Edit box focus texture (made safe for Retail)

local chgEditFocusHide;

local function setChatEditFocus(showFocus)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local focus1 = _G[chatFrameName .. "EditBox" .. "FocusLeft"];
		local focus2 = _G[chatFrameName .. "EditBox" .. "FocusRight"];
		local focus3 = _G[chatFrameName .. "EditBox" .. "FocusMid"];
		if (focus1 and focus2 and focus3) then
			if (showFocus) then
				focus1:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorderFocus-Left"); focus2:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorderFocus-Right"); focus3:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorderFocus-Mid");
			else
				focus1:SetTexture(nil); focus2:SetTexture(nil); focus3:SetTexture(nil);
			end
		end
	end
end

local function updateEditFocusHide()
	local hideFocus = module:getOption("chatEditHideFocus");
	if (not hideFocus) then
		if (chgEditFocusHide) then chgEditFocusHide = false; setChatEditFocus(true); end
	else
		setChatEditFocus(false); chgEditFocusHide = true;
	end
end

--------------------------------------------
-- Edit box border texture (made safe for Retail)

local chgEditBorderHide;

local function setChatEditBorder(showBorder)
	for _, chatFrameName in pairs(CHAT_FRAMES) do
		local border1 = _G[chatFrameName .. "EditBox" .. "Left"];
		local border2 = _G[chatFrameName .. "EditBox" .. "Right"];
		local border3 = _G[chatFrameName .. "EditBox" .. "Mid"];
		if (border1 and border2 and border3) then
			if (showBorder) then
				border1:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left2"); border2:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Right2"); border3:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Mid2");
			else
				border1:SetTexture(nil); border2:SetTexture(nil); border3:SetTexture(nil);
			end
		end
	end
end

local function updateEditBorderHide()
	local hideBorder = module:getOption("chatEditHideBorder");
	if (not hideBorder) then
		if (chgEditBorderHide) then chgEditBorderHide = false; setChatEditBorder(true); end
	else
		setChatEditBorder(false); chgEditBorderHide = true;
	end
end

--------------------------------------------
-- Miscellaneous

local function updateChat()
	updateFriendsButtonHide();
	updateChatMenuButtonHide();
	updateChatButtonsHide();
	updateChatScrolling();
	updateChatEditTop();
	updateChatTimeVisible();
	updateChatFadeDuration();
	updateChatFadingDisable();
	updateChatClamping();
	updateChatTabAlphas();
	updateChatResizeButtons();
	updateChatResizeMouseover();
	updateChatStickyFlags();
	updateChatNoResizeLimits();
	updateChatDefaultAlphas();
	updateEditFocusHide();
	updateEditBorderHide();
end

do
	local tempChatFrame
	if FCF_SetTemporaryWindowType then
		hooksecurefunc("FCF_SetTemporaryWindowType", function(chatFrame) tempChatFrame = chatFrame end)
	end
	if FCF_OpenTemporaryWindow then
		hooksecurefunc("FCF_OpenTemporaryWindow", function()
			if tempChatFrame then createChatFrameResizeButtons(tempChatFrame); updateChat(); end
		end)
	end
end

--------------------------------------------
-- General Initializer

module.chatupdate = function(self, type, value)
	if ( type == "init" ) then
		module:regEvent("PLAYER_ENTERING_WORLD", function()
			updateChat();
			module:unregEvent("PLAYER_ENTERING_WORLD");
		end);
	else
		if ( type == "chatArrows" ) then updateChatMenuButtonHide(); updateChatButtonsHide();
		elseif ( type == "friendsMicroButton" ) then updateFriendsButtonHide();
		elseif ( type == "chatEditMove" ) then updateChatEditTop();
		elseif ( type == "chatEditPosition" ) then updateChatEditTop();
		elseif ( type == "chatDisableFading" ) then updateChatFadingDisable();
		elseif ( type == "chatTimeVisible" ) then updateChatTimeVisible();
		elseif ( type == "chatFadeDuration" ) then updateChatFadeDuration();
		elseif ( type == "chatClamping" ) then updateChatClamping();
		elseif (type == "chatResizeEnabled1" or type == "chatResizeEnabled2" or type == "chatResizeEnabled3" or type == "chatResizeEnabled4") then updateChatResizeButtons();
		elseif ( type == "chatResizeMouseover" ) then updateChatResizeMouseover();
		elseif ( type == "chatMinMaxSize" ) then updateChatNoResizeLimits();
		elseif ( type == "chatEditHideFocus" ) then updateEditFocusHide();
		elseif ( type == "chatEditHideBorder" ) then updateEditBorderHide();
		else
			for i, optTable in ipairs(module.optChatTabOpacity) do
				for j, tbl in ipairs(optTable.sliders) do if ( type == tbl.option ) then updateChatTabAlpha(tbl); return; end end
			end
			for i, optTable in ipairs(module.optChatFrameOpacity) do
				for j, tbl in ipairs(optTable.sliders) do if ( type == tbl.option ) then updateChatDefaultAlpha(tbl); return; end end
			end
			for i, stickyInfo in ipairs(module.chatStickyTypes) do
				if (type == "chatSticky" .. stickyInfo.chatType) then updateChatStickyFlag(stickyInfo); return; end
			end
		end
	end
end