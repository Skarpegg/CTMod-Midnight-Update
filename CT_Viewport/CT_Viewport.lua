------------------------------------------------
--                CT_Viewport                 --
--                                            --
-- Allows you to customize the rendered game  --
-- area, resulting in an overall more         --
-- customizable and usable  user interface.   --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes (ddc) since 2018  --
------------------------------------------------

-- Initialization
local MODULE_NAME, module = ...;
local MODULE_VERSION = strmatch(C_AddOns.GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

CT_Library:registerModule(module);
_G[MODULE_NAME] = module --.publicInterface;
local public = _G[MODULE_NAME]

-- See localization.lua
module.text = module.text or { };
local L = module.text;

module.currOffset = {0, 0, 0, 0}

local frameClearAllPoints, frameSetAllPoints, frameSetPoint;
local savedViewport		-- current settings
local ivalues = {0,0,0,0,0,0};	-- limits for the inner frame in the options panel

-- Public API

-- Returns true if the viewport is anything other than 0 0 0 0
function public:IsViewportCustomized()
	local offset = module.currOffset;
	return offset[1] ~= 0 and offset[2] ~= 0 and offset[3] ~= 0 and offset[4]~= 0
end

-- Returns the current custom viewport settings as four variables: L, R, T, B
function public:GetViewportSettings()
	local offset = module.currOffset;
	return tonumber(offset[1]), tonumber(offset[2]), tonumber(offset[3]), tonumber(offset[4]), tonumber(savedViewport[1]), tonumber(savedViewport[2]), tonumber(savedViewport[3]), tonumber(savedViewport[4]);	--tonumber is just cheating to create a new copy of the number
end

-- Slash command to display the frame
SlashCmdList["VIEWPORT"] = function(msg)
	module:showModuleOptions();
	local iStart, iEnd, left, right, top, bottom = string.find(msg, "^(%d+%.?%d?) (%d+%.?%d?) (%d+%.?%d?) (%d+%.?%d?)$");
	if ( left and right and top and bottom ) then
		local screenRes = module.screenRes;
		if not screenRes then
			screenRes = {1920, 1080}
		end
		left = min(tonumber(left), screenRes[1]/2 - 1);
		right = min(tonumber(right), screenRes[1]/2 - 1, screenRes[1]/2 - left);
		top = min(tonumber(top), screenRes[2]/2 - 1);
		bottom = min(tonumber(bottom), screenRes[2]/2 - 1, screenRes[2]/2 - top);
		
		if (left ~= 0 or right ~= 0 or top ~= 0 or bottom ~= 0) then
			module.CheckKeepSettings();
		end
		
		CT_ViewportLeftEB:SetText(0.5*floor(left*2 + 0.1));
		CT_ViewportRightEB:SetText(0.5*floor(right*2 + 0.1));
		CT_ViewportTopEB:SetText(0.5*floor(top*2 + 0.1));
		CT_ViewportBottomEB:SetText(0.5*floor(bottom*2 + 0.1));
		
		module.ApplyViewport(left, right, top, bottom);
		module.ApplyInnerViewport(left, right, top, bottom);
	end
end
SLASH_VIEWPORT1 = "/viewport";
SLASH_VIEWPORT2 = "/ctvp";
SLASH_VIEWPORT3 = "/ctviewport";

function module.GetQuotient(number)
	number = format("%.2f", number);

	for a = 1, 100, 1 do
		for b = 1, 100, 1 do
			if ( format("%.2f", b / a) == number ) then
				return format("%.2f |r(|c00FFFFFF%d/%d|r)", number, b, a);
			elseif ( format("%.2f", a / b) == number ) then
				return format("%.2f |r(|c00FFFFFF%d/%d|r)", number, a, b);
			end
		end
	end
	return number;
end

-- Resizing functions
function module.Resize(button, anchorPoint)
	module.UpdateInnerFrameBounds();
	local iframe = CT_ViewportInnerFrame;

	button:GetParent():StartSizing(anchorPoint);
	module.isResizing = anchorPoint;

	-- A bit hackish, but meh, it works
	if ( anchorPoint == "LEFT" ) then
		button:GetParent():SetMaxResize(ivalues[5] - (ivalues[2] - iframe:GetRight()), ivalues[6]);

	elseif ( anchorPoint == "RIGHT" ) then
		button:GetParent():SetMaxResize(ivalues[5] - (iframe:GetLeft() - ivalues[1]), ivalues[6]);

	elseif ( anchorPoint == "TOP" ) then
		button:GetParent():SetMaxResize(ivalues[5], ivalues[6] - (iframe:GetBottom() - ivalues[4]));

	elseif ( anchorPoint == "BOTTOM" ) then
		button:GetParent():SetMaxResize(ivalues[5], ivalues[6] - (ivalues[3] - iframe:GetTop()));

	elseif ( anchorPoint == "TOPLEFT" ) then
		button:GetParent():SetMaxResize(ivalues[5] - (ivalues[2] - iframe:GetRight()), ivalues[6] - (iframe:GetBottom() - ivalues[4]));

	elseif ( anchorPoint == "TOPRIGHT" ) then
		button:GetParent():SetMaxResize(ivalues[5] - (iframe:GetLeft() - ivalues[1]), ivalues[6] - (iframe:GetBottom() - ivalues[4]));

	elseif ( anchorPoint == "BOTTOMLEFT" ) then
		button:GetParent():SetMaxResize(ivalues[5] - (ivalues[2] - iframe:GetRight()), ivalues[6] - (ivalues[3] - iframe:GetTop()));

	elseif ( anchorPoint == "BOTTOMRIGHT" ) then
		button:GetParent():SetMaxResize(ivalues[5] - (iframe:GetLeft() - ivalues[1]), ivalues[6] - (ivalues[3] - iframe:GetTop()));
	end
end

function module.StopResize(button)
	local screenRes = module.screenRes;
	local currOffset = module.currOffset;

	button:GetParent():StopMovingOrSizing();
	module.isResizing = nil;

	-- We need to re-anchor the inner frame after the player drags it.
	-- The game picks its own anchor when dragging stops, and the one that it picks
	-- is not what we need for the inner frame. Since the viewport window is near the
	-- center of the screen the game will anchor the inner frame using a CENTER
	-- anchor point to UIParent. What we really need are TOPLEFT and BOTTOMRIGHT
	-- anchor points to the outer frame.
	module.ApplyInnerViewport(
		module.currOffset[1], -- left
		module.currOffset[2], -- right
		module.currOffset[3], -- top
		module.currOffset[4] -- bottom
	);

	local value1 = (screenRes[1] - currOffset[1] - currOffset[2]);
	local value2 = (screenRes[2] - currOffset[3] - currOffset[4]);
	local value3
	if (value2 == 0) then
		value3 = 0;
	else
		value3 = value1 / value2;
	end
	CT_ViewportAspectRatioNewText:SetText(L["CT_Viewport/Options/AspectRatio/NewPattern"]:format(module.GetQuotient(value3)));

	local value1 = screenRes[1];
	local value2 = screenRes[2];
	local value3
	if (value2 == 0) then
		value3 = 0;
	else
		value3 = value1 / value2;
	end
	CT_ViewportAspectRatioDefaultText:SetText(L["CT_Viewport/Options/AspectRatio/DefaultPattern"]:format(module.GetQuotient(value3)));
end

-- Get initial size values
function module.UpdateInnerFrameBounds()
	local bframe = CT_ViewportBorderFrame;

	-- Calculate limits of inner frame using the border frame since it will
	-- always be in a fixed position, unlike the inner frame whose edges may get
	-- dragged by the user.
	ivalues[1] = bframe:GetLeft() + 4;
	ivalues[2] = bframe:GetRight() - 4;
	ivalues[3] = bframe:GetTop() - 4;
	ivalues[4] = bframe:GetBottom() + 4;
	ivalues[5] = ivalues[2] - ivalues[1];  -- width
	ivalues[6] = ivalues[3] - ivalues[4];  -- height

	return ivalues;
end

-- Apply the viewport settings
function module.ApplyViewport(left, right, top, bottom)
	local screenRes = module.screenRes;

	-- UIParent values change when the UI scale is changed by the user,
	-- or if the video resolution is changed by the user.
	local parentWidth = UIParent:GetWidth();
	local parentHeight = UIParent:GetHeight();
	local parentScale = UIParent:GetScale();

	if ( not left and CT_ViewportInnerFrame) then
		module.UpdateInnerFrameBounds()
		local iframe = CT_ViewportInnerFrame;

		if (ivalues[5] == 0) then
			right = 0;
			left = 0;
		else
			right = ((ivalues[2] - iframe:GetRight()) / ivalues[5]) * screenRes[1];
			left = ((iframe:GetLeft() - ivalues[1]) / ivalues[5]) * screenRes[1];
		end
		if (ivalues[6] == 0) then
			top = 0;
			bottom = 0;
		else
			top = ((ivalues[3] - iframe:GetTop()) / ivalues[6]) * screenRes[2];
			bottom = ((iframe:GetBottom() - ivalues[4]) / ivalues[6]) * screenRes[2];
		end
	end
	if (left) then
		if ( right < 0 ) then
			right = 0;
		end
		if ( left < 0 ) then
			left = 0;
		end
		if ( top < 0 ) then
			top = 0;
		end
		if ( bottom < 0 ) then
			bottom = 0;
		end
	else
		-- this shouldn't happen
		left, right, top, bottom = 0, 0, 0, 0;
	end

	savedViewport[1] = floor(left*2+0.1)*.5
	savedViewport[2] = floor(right*2+0.1)*.5
	savedViewport[3] = floor(top*2+0.1)*.5
	savedViewport[4] = floor(bottom*2+0.1)*.5
	module:setOption("savedViewport", savedViewport, false)

	local update = true;
	if (WorldFrame:IsProtected() and InCombatLockdown()) then
		update = false;
	end
	if (update) then
		frameClearAllPoints(WorldFrame);

		local ULx;
		local ULy;
		local LRx
		local LRy

		if (screenRes[1] == 0) then
			ULx = 0;
		else
			ULx = (left / screenRes[1]) * (parentWidth * parentScale);
		end
		if (screenRes[2] == 0) then
			ULy = 0;
		else
			ULy = (top / screenRes[2]) * (parentHeight * parentScale);
		end
		frameSetPoint(WorldFrame, "TOPLEFT", ULx, -ULy);

		if (screenRes[1] == 0) then
			LRx = 0;
		else
			LRx = (right / screenRes[1]) * (parentWidth * parentScale);
		end
		if (screenRes[2] == 0) then
			LRy = 0;
		else
			LRy = (bottom / screenRes[2]) * (parentHeight * parentScale);
		end
		frameSetPoint(WorldFrame, "BOTTOMRIGHT", -LRx, LRy);
		
		module.updateGradientPoints(ULx, ULy, LRx, LRy)

	end
end

function module.ApplySavedViewport()
	local screenRes = module.screenRes;
	if screenRes then
		savedViewport[1] = min(tonumber(savedViewport[1]), screenRes[1]/2 - 1);
		savedViewport[2] = min(tonumber(savedViewport[2]), screenRes[1]/2 - 1);
		if (savedViewport[1] + savedViewport[2] > screenRes[1] - 100) then
			savedViewport[1] = screenRes[1]/2 - 50;
			savedViewport[2] = screenRes[1]/2 - 50;
		end
		savedViewport[3] = min(tonumber(savedViewport[3]), screenRes[2]/2 - 1);
		savedViewport[4] = min(tonumber(savedViewport[4]), screenRes[2]/2 - 1);
		if (savedViewport[3] + savedViewport[4] > screenRes[2] - 100) then
			savedViewport[3] = screenRes[2]/2 - 50;
			savedViewport[4] = screenRes[2]/2 - 50;
		end
	end
	if (tonumber(savedViewport[1]) + tonumber(savedViewport[2]) + tonumber(savedViewport[3]) + tonumber(savedViewport[4]) > 0 and not module:getOption("CTVP_SuppressLoadingMessage")) then
		C_Timer.After(8, function() print("|cFFFFFF00CT_Viewport is currently active! |n      |r/ctvp|cFFFFFF00 to tweak settings |n      |r/ctvp 0 0 0 0|cFFFFFF00 to restore default"); end);
	end
	module.ApplyViewport(
		savedViewport[1],
		savedViewport[2],
		savedViewport[3],
		savedViewport[4]
	);
end

-- after pressing 'okay' ensure the screen is visible
do
	local newSettingsApplied, keepSettingsTicker;
	function module.CheckKeepSettings()
		if (newSettingsApplied) then
			-- check is already in progress; after 20 seconds revert if the user hasn't presed the button
			if (GetTime() > newSettingsApplied + 20) then
				module.applyButton:Show();
				module.resetButton:Show();
				module.keepSettingsButton:Hide();
				newSettingsApplied = nil;
				if (keepSettingsTicker) then
					keepSettingsTicker:Cancel();
					keepSettingsTicker = nil
				end
				module.ApplyViewport(0, 0, 0, 0);
			else
				module.keepSettingsButton:SetText(L["CT_Viewport/Options/Viewport/KeepSettingsPattern"]:format(newSettingsApplied + 20 - GetTime()));
			end
		else
			-- start of a new check
			newSettingsApplied = GetTime();
			module.applyButton:Hide();
			module.resetButton:Hide();
			module.keepSettingsButton:SetText(L["CT_Viewport/Options/Viewport/KeepSettingsPattern"]:format(20));
			module.keepSettingsButton:Show();
			keepSettingsTicker = keepSettingsTicker or C_Timer.NewTicker(0.25, module.CheckKeepSettings)
		end
	end


	function module.KeepSettings()
		newSettingsApplied = nil;
		if (keepSettingsTicker) then
			keepSettingsTicker:Cancel();
			keepSettingsTicker = nil
		end
		module.applyButton:Show();
		module.resetButton:Show();
		module.keepSettingsButton:Hide();
	end
end

-- Apply saved settings to the inner viewport
function module.ApplyInnerViewport(left, right, top, bottom)
	local screenRes = module.screenRes;
	local iframe = CT_ViewportInnerFrame;

	CT_ViewportLeftEB:SetText(0.5*floor(left*2 + 0.1));
	CT_ViewportRightEB:SetText(0.5*floor(right*2 + 0.1));
	CT_ViewportTopEB:SetText(0.5*floor(top*2 + 0.1));
	CT_ViewportBottomEB:SetText(0.5*floor(bottom*2 + 0.1));

	module.currOffset = {
		0.5*floor(left*2 + 0.1),
		0.5*floor(right*2 + 0.1),
		0.5*floor(top*2 + 0.1),
		0.5*floor(bottom*2 + 0.1)
	};

	if (CT_ViewportAspectRatioNewText) then
		local value1 = (screenRes[1] - left - right);
		local value2 = (screenRes[2] - top - bottom);
		local value3
		if (value2 == 0) then
			value3 = 0;
		else
			value3 = value1 / value2;
		end
		CT_ViewportAspectRatioNewText:SetText(L["CT_Viewport/Options/AspectRatio/NewPattern"]:format(module.GetQuotient(value3)));
	end

	if (CT_ViewportAspectRatioDefaultText) then
		local value1 = screenRes[1];
		local value2 = screenRes[2];
		local value3
		if (value2 == 0) then
			value3 = 0;
		else
			value3 = value1 / value2;
		end
		CT_ViewportAspectRatioDefaultText:SetText(L["CT_Viewport/Options/AspectRatio/DefaultPattern"]:format(module.GetQuotient(value3)));
	end

	if (screenRes[1] == 0) then
		left = 0;
		right = 0;
	else
		left = left * (ivalues[5] / screenRes[1]);
		right = right * (ivalues[5] / screenRes[1]);
	end

	if (screenRes[2] == 0) then
		top = 0;
		bottom = 0;
	else
		top = top * (ivalues[6] / screenRes[2]);
		bottom = bottom * (ivalues[6] / screenRes[2]);
	end

	iframe:ClearAllPoints();
	iframe:SetPoint("TOPLEFT", "CT_ViewportBorderFrame", "TOPLEFT", left + 4, -(top + 4));
	iframe:SetPoint("BOTTOMRIGHT", "CT_ViewportBorderFrame", "BOTTOMRIGHT", -(right + 4), bottom + 4);

	local frameTop = iframe:GetTop();
	local frameBottom = iframe:GetBottom();
	local frameLeft = iframe:GetLeft();
	local frameRight = iframe:GetRight();

	if ( frameTop and frameBottom and frameLeft and frameRight ) then
		iframe:SetHeight(frameTop - frameBottom);
		iframe:SetWidth(frameRight - frameLeft);
	else
		module.awaitingValues = true;
	end
end

-- Change a side of the viewport
function module.ChangeViewportSide(editBox)
	local value = tonumber(editBox:GetText());
	if ( not value ) then
		return;
	end
	value = abs(value);
	local id = editBox:GetID();

	local left = module.currOffset[1];
	local right = module.currOffset[2];
	local top = module.currOffset[3];
	local bottom = module.currOffset[4];

	if ( id == 1 ) then
		-- Left
		module.ApplyInnerViewport(value, right, top, bottom);
	elseif ( id == 2 ) then
		-- Right
		module.ApplyInnerViewport(left, value, top, bottom);
	elseif ( id == 3 ) then
		-- Top
		module.ApplyInnerViewport(left, right, value, bottom);
	elseif ( id == 4 ) then
		-- Bottom
		module.ApplyInnerViewport(left, right, top, value);
	end
end

function module.Init()
	if C_VideoOptions and C_VideoOptions.GetCurrentGameWindowSize then
		-- WoW 10.x
		local size = C_VideoOptions.GetCurrentGameWindowSize()
		if size.x and size.y and size.x > 0 and size.y > 0 then
			module.screenRes = { size.x, size.y }
			module.awaitingValues = true
		end
	else
		-- prior to WoW 10.x
		local currRes = GetCurrentResolution()
		if currRes > 0 then
			currRes = select(currRes, GetScreenResolutions())
		else
			currRes = GetCVar("gxWindowedResolution")
		end
		if currRes then
			local __, __, x, y = string.find(currRes, "(%d+)x(%d+)")
			if x and y then
				module.screenRes = {tonumber(x), tonumber(y)}
				module.awaitingValues = true
			end
		end
	end
end

-----------------------
-- Gradient textures

do
	local frame = CreateFrame("Frame")
	frame:SetFrameStrata("BACKGROUND")
	frame:SetFrameLevel(0)
	frame:SetAllPoints()
	frame:Hide()
	
	local left = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	left:SetPoint("RIGHT", WorldFrame, "LEFT")
	left:SetPoint("BOTTOM", WorldFrame)
	left:SetPoint("TOP", WorldFrame)
	
	local right = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	right:SetPoint("LEFT", WorldFrame, "RIGHT")
	right:SetPoint("BOTTOM", WorldFrame)
	right:SetPoint("TOP", WorldFrame)
	
	local bottom  = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	bottom:SetPoint("LEFT", left)
	bottom:SetPoint("RIGHT", right)
	bottom:SetPoint("TOP", WorldFrame, "BOTTOM")	
	
	local top  = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	top:SetPoint("LEFT", left)
	top:SetPoint("RIGHT", right)
	top:SetPoint("BOTTOM", WorldFrame, "TOP")
	
	function module.updateGradientPoints(ULx, ULy, LRx, LRy)		--called by ApplyViewport() when out of combat
		if (ULx > 0 or ULy > 0 or LRx > 0 or LRy > 0) then
			left:SetPoint("LEFT", WorldFrame, -ULx, 0)
			right:SetPoint("RIGHT", WorldFrame, LRx, 0)
			bottom:SetPoint("BOTTOM", WorldFrame, 0, -LRy)
			top:SetPoint("TOP", WorldFrame, 0, ULy)
			frame:Show()
		else
			frame:Hide()
		end
	end
	
	function module.setGradientColor(color)		--called by ApplyViewport() when it happens
		local r, g, b, a
		if (color) then
			r, g, b, a = color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1
		else
			r, g, b, a = 0, 0, 0, 1
		end

		left:SetColorTexture(r, g, b, a)
		right:SetColorTexture(r, g, b, a)
		bottom:SetColorTexture(r, g, b, a)
		top:SetColorTexture(r, g, b, a)
	end

end


-----------------------
-- Apply Settings

function module:update(option, value)
	if (option == "init") then
		
		savedViewport = module:getOption("savedViewport") or {0,0,0,0}
		
		-- Temporary code to transition from 9.1.0.2 to 9.1.0.3
		savedViewport[5] = nil
		savedViewport[6] = nil
		savedViewport[7] = nil
		
		-- Temporary code to transition from 9.0.2.4 to 9.0.5.x
		if (CT_Viewport_Saved) then
			
			CT_ViewportBackup = CT_ViewportBackup or {}

			local oldSetOption = module.setOption
			function module:setOption(option, value, ...)
				oldSetOption(self, option, value, ...)
				local key = module:getCharKey()
				CT_ViewportBackup[key] = CT_ViewportBackup[key] or {}
				CT_ViewportBackup[key][option] = value
			end
			
			if (#CT_Viewport_Saved > 0) then
				-- avoid deleting other toons' data when migrating saved variable types
				for charKey, val in pairs(CT_ViewportBackup) do	
					module.options[charKey] = val
				end

				-- convert from an olds note format
				savedViewport[1], savedViewport[2], savedViewport[3], savedViewport[4]
					= CT_Viewport_Saved[1], CT_Viewport_Saved[2], CT_Viewport_Saved[3], CT_Viewport_Saved[4]
				wipe(CT_Viewport_Saved)
			end
		end

		module:setOption("savedViewport", savedViewport, false)
	
		-- The former on-load and VARIABLES_LOADED until 9.0.0.1
		local dummyFrame = CreateFrame("Frame")
		frameClearAllPoints = dummyFrame.ClearAllPoints
		frameSetAllPoints = dummyFrame.SetAllPoints
		frameSetPoint = dummyFrame.SetPoint

		hooksecurefunc(WorldFrame, "ClearAllPoints", module.ApplySavedViewport)
		hooksecurefunc(WorldFrame, "SetAllPoints", module.ApplySavedViewport)
		hooksecurefunc(WorldFrame, "SetPoint", module.ApplySavedViewport)

		-- Beginning in Battle for Azeroth, some raid encounters have cinematics during combat.  Examples: Jaina freezing the sea, or N'Zoth special area on mythic mode
		CinematicFrame:SetScript("OnShow", nil)
		CinematicFrame:SetScript("OnHide", nil)

		-- The game reloads the UI when switching between different aspect ratios.
		-- The game does not reload the UI when switching between resolutions with the same aspect ratio.
		-- The game does not reload the UI when switching between windowed, windowed (fullscreen),
		-- and fullscreen modes.
		-- The game does not reload the UI when changing the UI scale slider. We'll catch this indirectly
		-- via the OnShow script when the viewport window is re-opened.

		-- Handle screen resolution changes.		
		if Settings and Settings.SetOnValueChangedCallback then
			-- WoW 10.x
			Settings.SetOnValueChangedCallback("PROXY_DISPLAY_MODE", function()
				module.Init()
				module.ApplySavedViewport()
				module.hasAppliedViewport = nil
			end)
		else
			-- prior to WoW 10.x
			hooksecurefunc("SetScreenResolution", function(res)
				module.Init()
				module.ApplySavedViewport()
				module.hasAppliedViewport = nil
			end)
		end


		module.setGradientColor(module:getOption("color"))

		module.Init()
	
		module.ApplySavedViewport()
		
	elseif (option == "color") then
		module.setGradientColor(value)
		
	end
end

--------------------------------------------
-- Options Frame Code


function module.frame()
	-- see CT_Library
	local optionsFrameList = module:framesInit();

	-- helper functions to shorten the code a bit
	local optionsAddFrame = function(offset, size, details, data) module:framesAddFrame(optionsFrameList, offset, size, details, data); end
	local optionsAddObject = function(offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details); end
	local optionsAddScript = function(name, func) module:framesAddScript(optionsFrameList, name, func); end
	local optionsAddTooltip = function(text) module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL); end); end
	local optionsBeginFrame = function(offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data); end
	local optionsEndFrame = function() module:framesEndFrame(optionsFrameList); end
		
	-- commonly used colors
	local textColor1 = "#0.9:0.9:0.9";
	local textColor2 = "#0.7:0.7:0.7";
	
	-- Tips
	optionsAddObject(-10, 17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_Viewport/Options/Tips/Heading"]);
	optionsAddObject(-10, 1*14, "font#tl:5:%y#" .. L["CT_Viewport/Options/Tips/Line1"] .. textColor2 .. ":l:300");
	optionsAddObject( -2, 1*14, "font#tl:15:%y#/ctvp" .. textColor1 .. ":l");
	optionsAddObject( 14, 1*14, "font#tl:115:%y#" .. L["CT_Viewport/Options/Tips/Line2"] .. textColor2 .. ":l:190");
	optionsAddObject(  0, 1*14, "font#tl:15:%y#/ctvp 0 0 0 0" .. textColor1 .. ":l");
	optionsAddObject( 14, 1*14, "font#tl:115:%y#" .. L["CT_Viewport/Options/Tips/Line3"] .. textColor2 .. ":l:190");
	optionsAddObject(  0, 1*14, "font#tl:15:%y#/ctvp 5 20 15 0" .. textColor1 .. ":l");
	optionsAddObject( 14, 1*14, "font#tl:115:%y#" .. L["CT_Viewport/Options/Tips/Line4"] .. textColor2 .. ":l:190");
	--optionsAddObject(-10, 1*14, "font#tl:5:%y#" .. L["CT_Viewport/Options/Tips/Line5"] .. textColor2 .. ":l:300");  "Alternatively, set custom values below."  Removed, because its rendundant.

	-- Heading
	optionsAddObject(-10, 17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_Viewport/Options/Viewport/Heading"]);
	
	-- Apply/Cancel/Keep Settings
	optionsBeginFrame(-8, 32, "button#tr:t:-10:%y#s:125:32#v:GameMenuButtonTemplate#" .. L["CT_Viewport/Options/Viewport/ApplyButton"]);
		optionsAddScript("onload", function(button)
			module.applyButton = button;
			button:HookScript("OnClick", function()
				CT_ViewportLeftEB:ClearFocus();
				CT_ViewportRightEB:ClearFocus();
				CT_ViewportTopEB:ClearFocus();
				CT_ViewportBottomEB:ClearFocus();
				module.CheckKeepSettings();
				module.ApplyViewport();
			end);
		end);
		optionsAddTooltip({L["CT_Viewport/Options/Viewport/ApplyButton"], L["CT_Viewport/Options/Viewport/ApplyTip"] .. textColor2});
	optionsEndFrame();
	
	optionsBeginFrame(32, 32, "button#tl:t:10:%y#s:125:32#v:GameMenuButtonTemplate#" .. L["CT_Viewport/Options/Viewport/ResetButton"]);
		optionsAddScript("onload", function(button)
			module.resetButton = button;
			button:HookScript("OnClick", function()
				module.ApplyViewport(0, 0, 0, 0)
			end);
		end);
		optionsAddTooltip({L["CT_Viewport/Options/Viewport/ResetButton"], "/ctvp 0 0 0 0" .. textColor2});
	optionsEndFrame();
	
	optionsBeginFrame(32, 32, "button#t:0:%y#s:270:32#v:GameMenuButtonTemplate#Keep Settings?");
		optionsAddScript("onload", function(button)
			module.keepSettingsButton = button;
			button:Hide();
			button:HookScript("OnClick", module.KeepSettings);
		end);
	optionsEndFrame();
	
	-- Manual edit boxes (top, left, right and bottom)
	optionsBeginFrame(-8, 32, "editbox#t:0:%y#n:CT_ViewportTopEB#i:3#ChatFontNormal");
		optionsAddScript("onload", function(eb)
			eb:SetAutoFocus(false);
			eb:SetMaxLetters(5);
			eb:SetSize(40, 25);
			eb:SetJustifyH("CENTER");

			eb.texL = eb:CreateTexture(nil, "BACKGROUND")
			eb.texL:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left");
			eb.texL:SetSize(40, 32);
			eb.texL:SetPoint("LEFT", -10, 0);
			eb.texL:SetTexCoord(0, 0.156246, 0, 1);
			
			eb.texR = eb:CreateTexture(nil, "BACKGROUND")
			eb.texR:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Right");
			eb.texR:SetSize(25, 32);
			eb.texR:SetPoint("RIGHT", 10, 0);
			eb.texR:SetTexCoord(0.9, 1, 0, 1);
			
			eb.texM = eb:CreateTexture(nil, "BACKGROUND")
			eb.texM:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left");
			eb.texM:SetSize(25, 32);
			eb.texM:SetPoint("LEFT", eb.texL, "RIGHT");
			eb.texM:SetPoint("RIGHT", eb,texL, "LEFT");
			eb.texM:SetTexCoord(0.29296875, 1, 0, 1);
			
			eb:HookScript("OnEscapePressed", function()
				if (eb.ctUndo) then
					eb:SetText(eb.ctUndo);
				end
				eb:ClearFocus();
			end);
			
			eb:HookScript("OnEnterPressed", function()
				eb.ctUndo = eb:GetText();
				module.ChangeViewportSide(eb);
			end);
			
			eb:HookScript("OnTabPressed", function()
				if (IsShiftKeyDown()) then
					CT_ViewportRightEB:SetFocus();
				else
					CT_ViewportBottomEB:SetFocus();
				end
			end);
			
			eb:HookScript("OnTextChanged", function()
				if ( ( not tonumber(eb:GetText()) or ( eb.limitation and tonumber(eb:GetText()) > eb.limitation ) ) and strlen(eb:GetText()) > 0 ) then
					if ( tonumber(eb:GetText()) and eb.limitation and tonumber(eb:GetText()) >  eb.limitation ) then
						eb:SetText(eb.limitation);
					else
						eb:SetText(strsub(eb:GetText(), 1, strlen(eb:GetText())-1));
					end
				end
			end);
			
			eb:HookScript("OnEditFocusGained", function()
				eb.ctUndo = eb:GetText();
				eb:HighlightText();
			end);
			
			eb:HookScript("OnEditFocusLost", function()
				eb:HighlightText(0, 0);
				module.ChangeViewportSide(eb);
			end);
		end);
	optionsEndFrame();
	
	optionsBeginFrame(32, 32, "editbox#tl:tl:8:%y#n:CT_ViewportLeftEB#i:1#ChatFontNormal");
		optionsAddScript("onload", function(eb)
			eb:SetAutoFocus(false);
			eb:SetMaxLetters(5);
			eb:SetSize(40, 25);
			eb:SetJustifyH("CENTER");

			eb.texL = eb:CreateTexture(nil, "BACKGROUND")
			eb.texL:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left");
			eb.texL:SetSize(40, 32);
			eb.texL:SetPoint("LEFT", -10, 0);
			eb.texL:SetTexCoord(0, 0.156246, 0, 1);
			
			eb.texR = eb:CreateTexture(nil, "BACKGROUND")
			eb.texR:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Right");
			eb.texR:SetSize(25, 32);
			eb.texR:SetPoint("RIGHT", 10, 0);
			eb.texR:SetTexCoord(0.9, 1, 0, 1);
			
			eb.texM = eb:CreateTexture(nil, "BACKGROUND")
			eb.texM:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left");
			eb.texM:SetSize(25, 32);
			eb.texM:SetPoint("LEFT", eb.texL, "RIGHT");
			eb.texM:SetPoint("RIGHT", eb,texL, "LEFT");
			eb.texM:SetTexCoord(0.29296875, 1, 0, 1);
			
			eb:HookScript("OnEscapePressed", function()
				if (eb.ctUndo) then
					eb:SetText(eb.ctUndo);
				end
				eb:ClearFocus();
			end);
			
			eb:HookScript("OnEnterPressed", function()
				eb.ctUndo = eb:GetText();
				module.ChangeViewportSide(eb);
			end);
			
			eb:HookScript("OnTabPressed", function()
				if (IsShiftKeyDown()) then
					CT_ViewportBottomEB:SetFocus();
				else
					CT_ViewportRightEB:SetFocus();
				end
			end);
			
			eb:HookScript("OnTextChanged", function()
				if ( ( not tonumber(eb:GetText()) or ( eb.limitation and tonumber(eb:GetText()) > eb.limitation ) ) and strlen(eb:GetText()) > 0 ) then
					if ( tonumber(eb:GetText()) and eb.limitation and tonumber(eb:GetText()) >  eb.limitation ) then
						eb:SetText(eb.limitation);
					else
						eb:SetText(strsub(eb:GetText(), 1, strlen(eb:GetText())-1));
					end
				end
			end);
			
			eb:HookScript("OnEditFocusGained", function()
				eb.ctUndo = eb:GetText();
				eb:HighlightText();
			end);
			
			eb:HookScript("OnEditFocusLost", function()
				eb:HighlightText(0, 0);
				module.ChangeViewportSide(eb);
			end);
		end);	
	optionsEndFrame();
	
	optionsBeginFrame( 32, 32, "editbox#tr:tr:-8:%y#n:CT_ViewportRightEB#i:2#ChatFontNormal");
		optionsAddScript("onload", function(eb)
			eb:SetAutoFocus(false);
			eb:SetMaxLetters(5);
			eb:SetSize(40, 25);
			eb:SetJustifyH("CENTER");

			eb.texL = eb:CreateTexture(nil, "BACKGROUND")
			eb.texL:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left");
			eb.texL:SetSize(40, 32);
			eb.texL:SetPoint("LEFT", -10, 0);
			eb.texL:SetTexCoord(0, 0.156246, 0, 1);
			
			eb.texR = eb:CreateTexture(nil, "BACKGROUND")
			eb.texR:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Right");
			eb.texR:SetSize(25, 32);
			eb.texR:SetPoint("RIGHT", 10, 0);
			eb.texR:SetTexCoord(0.9, 1, 0, 1);
			
			eb.texM = eb:CreateTexture(nil, "BACKGROUND")
			eb.texM:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left");
			eb.texM:SetSize(25, 32);
			eb.texM:SetPoint("LEFT", eb.texL, "RIGHT");
			eb.texM:SetPoint("RIGHT", eb,texL, "LEFT");
			eb.texM:SetTexCoord(0.29296875, 1, 0, 1);
			
			eb:HookScript("OnEscapePressed", function()
				if (eb.ctUndo) then
					eb:SetText(eb.ctUndo);
				end
				eb:ClearFocus();
			end);
			
			eb:HookScript("OnEnterPressed", function()
				eb.ctUndo = eb:GetText();
				module.ChangeViewportSide(eb);
			end);
			
			eb:HookScript("OnTabPressed", function()
				if (IsShiftKeyDown()) then
					CT_ViewportLeftEB:SetFocus();
				else
					CT_ViewportTopEB:SetFocus();
				end
			end);
			
			eb:HookScript("OnTextChanged", function()
				if ( ( not tonumber(eb:GetText()) or ( eb.limitation and tonumber(eb:GetText()) > eb.limitation ) ) and strlen(eb:GetText()) > 0 ) then
					if ( tonumber(eb:GetText()) and eb.limitation and tonumber(eb:GetText()) >  eb.limitation ) then
						eb:SetText(eb.limitation);
					else
						eb:SetText(strsub(eb:GetText(), 1, strlen(eb:GetText())-1));
					end
				end
			end);
			
			eb:HookScript("OnEditFocusGained", function()
				eb.ctUndo = eb:GetText();
				eb:HighlightText();
			end);
			
			eb:HookScript("OnEditFocusLost", function()
				eb:HighlightText(0, 0);
				module.ChangeViewportSide(eb);
			end);
		end);	
	optionsEndFrame();
	
	optionsBeginFrame(-180, 32, "editbox#t:0:%y#n:CT_ViewportBottomEB#i:4#ChatFontNormal");
		optionsAddScript("onload", function(eb)
			eb:SetAutoFocus(false);
			eb:SetMaxLetters(5);
			eb:SetSize(40, 25);
			eb:SetJustifyH("CENTER");

			eb.texL = eb:CreateTexture(nil, "BACKGROUND")
			eb.texL:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left");
			eb.texL:SetSize(40, 32);
			eb.texL:SetPoint("LEFT", -10, 0);
			eb.texL:SetTexCoord(0, 0.156246, 0, 1);
			
			eb.texR = eb:CreateTexture(nil, "BACKGROUND")
			eb.texR:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Right");
			eb.texR:SetSize(25, 32);
			eb.texR:SetPoint("RIGHT", 10, 0);
			eb.texR:SetTexCoord(0.9, 1, 0, 1);
			
			eb.texM = eb:CreateTexture(nil, "BACKGROUND")
			eb.texM:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left");
			eb.texM:SetSize(25, 32);
			eb.texM:SetPoint("LEFT", eb.texL, "RIGHT");
			eb.texM:SetPoint("RIGHT", eb,texL, "LEFT");
			eb.texM:SetTexCoord(0.29296875, 1, 0, 1);
			
			eb:HookScript("OnEscapePressed", function()
				if (eb.ctUndo) then
					eb:SetText(eb.ctUndo);
				end
				eb:ClearFocus();
			end);
			
			eb:HookScript("OnEnterPressed", function()
				eb.ctUndo = eb:GetText();
				module.ChangeViewportSide(eb);
			end);
			
			eb:HookScript("OnTabPressed", function()
				if (IsShiftKeyDown()) then
					CT_ViewportTopEB:SetFocus();
				else
					CT_ViewportLeftEB:SetFocus();
				end
			end);
			
			eb:HookScript("OnTextChanged", function()
				if ( ( not tonumber(eb:GetText()) or ( eb.limitation and tonumber(eb:GetText()) > eb.limitation ) ) and strlen(eb:GetText()) > 0 ) then
					if ( tonumber(eb:GetText()) and eb.limitation and tonumber(eb:GetText()) >  eb.limitation ) then
						eb:SetText(eb.limitation);
					else
						eb:SetText(strsub(eb:GetText(), 1, strlen(eb:GetText())-1));
					end
				end
			end);
			
			eb:HookScript("OnEditFocusGained", function()
				eb.ctUndo = eb:GetText();
				eb:HighlightText();
			end);
			
			eb:HookScript("OnEditFocusLost", function()
				eb:HighlightText(0, 0);
				module.ChangeViewportSide(eb);
			end);
		end);
	optionsEndFrame();
		
	-- Draggable Borders and Inner Frame (representing the viewport)
	
	-- called once only, by either CT_ViewportBorderFrame:OnLoad() or CT_ViewportInnerFrame:OnLoad() -- whichever happens last
	local function attachBorderAndInner()
		CT_ViewportInnerFrame:ClearAllPoints();
		CT_ViewportInnerFrame:SetPoint("TOPLEFT", CT_ViewportBorderFrame, "TOPLEFT", 4, -4);
		if CT_ViewportInnerFrame.SetMaxResize then
			CT_ViewportInnerFrame:SetMaxResize(CT_ViewportBorderFrame:GetWidth()-4, CT_ViewportBorderFrame:GetHeight()-4);
			CT_ViewportInnerFrame:SetMinResize((CT_ViewportBorderFrame:GetWidth()-4)/2, (CT_ViewportBorderFrame:GetHeight()-4)/2)
		else
			CT_ViewportInnerFrame:SetResizeBounds(
				(CT_ViewportBorderFrame:GetWidth()-4)/2,
				(CT_ViewportBorderFrame:GetHeight()-4)/2,
				CT_ViewportBorderFrame:GetWidth()-4,
				CT_ViewportBorderFrame:GetHeight()-4
			)
				
		end
		CT_ViewportInnerFrame:SetResizable(true);
		module.UpdateInnerFrameBounds();
		module.ApplyInnerViewport(
			savedViewport[1],
			savedViewport[2],
			savedViewport[3],
			savedViewport[4],
			savedViewport[5],
			savedViewport[6],
			savedViewport[7]
		);	
	end
	
	optionsBeginFrame(215, 180, "frame#t:0:%y#s:240:180#n:CT_ViewportBorderFrame");
		optionsAddScript("onload", function(frame)
			Mixin(frame, BackdropTemplateMixin or {});
			frame:SetBackdrop({
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground";
				tile = true;
				edgeSize = 3.2;
				tileSize = 3.2;
			});
			frame:SetBackdropBorderColor(1, 0, 0, 1);
			if (CT_ViewportInnerFrame) then
				attachBorderAndInner();
			end
		end);
	optionsEndFrame();
	
	optionsBeginFrame(0, 0, "frame#n:CT_ViewportInnerFrame");
		optionsAddScript("onload", function(frame)
			Mixin(frame, BackdropTemplateMixin or {});
			frame:SetBackdrop({
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground";
				tile = true;
				edgeSize = 3.2;
				tileSize = 3.2;
			});
			frame:SetBackdropBorderColor(1, 1, 0, 1);
			
			frame.background = frame:CreateTexture(nil, "BACKGROUND");
			frame.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground");
			frame.background:SetVertexColor(1, 1, 0, 0.1);
			frame.background:SetAllPoints();
			
			frame.fontString = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			frame.fontString:SetText(L["CT_Viewport/Options/Viewport/RenderedArea"]);
			
			frame.resizeTopLeft = CreateFrame("Button", nil, frame);
			frame.resizeTopLeft:SetSize(16,16);
			frame.resizeTopLeft:SetPoint("TOPLEFT");
			frame.resizeTopLeft:SetFrameLevel(frame:GetFrameLevel());
			frame.resizeTopLeft:HookScript("OnMouseDown", function(button) module.Resize(button, "TOPLEFT") end);
			frame.resizeTopLeft:HookScript("OnMouseUp", function(button) module.StopResize(button) end);
			
			frame.resizeTopRight = CreateFrame("Button", nil, frame);
			frame.resizeTopRight:SetSize(16,16);
			frame.resizeTopRight:SetPoint("TOPRIGHT");
			frame.resizeTopRight:SetFrameLevel(frame:GetFrameLevel());
			frame.resizeTopRight:HookScript("OnMouseDown", function(button) module.Resize(button, "TOPRIGHT") end);
			frame.resizeTopRight:HookScript("OnMouseUp", function(button) module.StopResize(button) end);
			
			frame.resizeBottomLeft = CreateFrame("Button", nil, frame);
			frame.resizeBottomLeft:SetSize(16,16);
			frame.resizeBottomLeft:SetPoint("BOTTOMLEFT");
			frame.resizeBottomLeft:SetFrameLevel(frame:GetFrameLevel());
			frame.resizeBottomLeft:HookScript("OnMouseDown", function(button) module.Resize(button, "BOTTOMLEFT") end);
			frame.resizeBottomLeft:HookScript("OnMouseUp", function(button) module.StopResize(button) end);
			
			frame.resizeBottomRight = CreateFrame("Button", nil, frame);
			frame.resizeBottomRight:SetSize(16,16);
			frame.resizeBottomRight:SetPoint("BOTTOMRIGHT");
			frame.resizeBottomRight:SetFrameLevel(frame:GetFrameLevel());
			frame.resizeBottomRight:HookScript("OnMouseDown", function(button) module.Resize(button, "BOTTOMRIGHT") end);
			frame.resizeBottomRight:HookScript("OnMouseUp", function(button) module.StopResize(button) end);
			
			frame.resizeRight = CreateFrame("Button", nil, frame);
			frame.resizeRight:SetPoint("TOPLEFT", frame.resizeTopRight, "BOTTOMLEFT");
			frame.resizeRight:SetPoint("BOTTOMRIGHT", frame.resizeBottomRight, "TOPRIGHT");
			frame.resizeRight:SetFrameLevel(frame:GetFrameLevel());
			frame.resizeRight:HookScript("OnMouseDown", function(button) module.Resize(button, "RIGHT") end);
			frame.resizeRight:HookScript("OnMouseUp", function(button) module.StopResize(button) end);
			
			frame.resizeLeft = CreateFrame("Button", nil, frame);
			frame.resizeLeft:SetPoint("TOPLEFT", frame.resizeTopLeft, "BOTTOMLEFT");
			frame.resizeLeft:SetPoint("BOTTOMRIGHT", frame.resizeBottomLeft, "TOPRIGHT");
			frame.resizeLeft:SetFrameLevel(frame:GetFrameLevel());
			frame.resizeLeft:HookScript("OnMouseDown", function(button) module.Resize(button, "LEFT") end);
			frame.resizeLeft:HookScript("OnMouseUp", function(button) module.StopResize(button) end);
			
			frame.resizeTop = CreateFrame("Button", nil, frame);
			frame.resizeTop:SetPoint("TOPLEFT", frame.resizeTopLeft, "TOPRIGHT");
			frame.resizeTop:SetPoint("BOTTOMRIGHT", frame.resizeTopRight, "BOTTOMLEFT");
			frame.resizeTop:SetFrameLevel(frame:GetFrameLevel());
			frame.resizeTop:HookScript("OnMouseDown", function(button) module.Resize(button, "TOP") end);
			frame.resizeTop:HookScript("OnMouseUp", function(button) module.StopResize(button) end);
			
			frame.resizeBottom = CreateFrame("Button", nil, frame);
			frame.resizeBottom:SetPoint("TOPLEFT", frame.resizeBottomLeft, "TOPRIGHT");
			frame.resizeBottom:SetPoint("BOTTOMRIGHT", frame.resizeBottomRight, "BOTTOMLEFT");
			frame.resizeBottom:SetFrameLevel(frame:GetFrameLevel());
			frame.resizeBottom:HookScript("OnMouseDown", function(button) module.Resize(button, "BOTTOM") end);
			frame.resizeBottom:HookScript("OnMouseUp", function(button) module.StopResize(button) end);
			
			if (CT_ViewportBorderFrame) then
				attachBorderAndInner();
			end
		end);
	optionsEndFrame();

	-- Aspect Ratio
	optionsAddObject(-25, 17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_Viewport/Options/AspectRatio/Heading"]);
	optionsAddObject( -5, 14, "font#tl:10:%y#r#n:CT_ViewportAspectRatioDefaultText#placeholder");
	optionsAddObject( -5, 14, "font#tl:10:%y#r#n:CT_ViewportAspectRatioNewText#placeholder");
	
	optionsBeginFrame(0, 0, "frame")
		optionsAddScript("onload", function(frame)
			
			frame:HookScript("OnHide", function()
				module.isResizing = nil;
				CT_ViewportInnerFrame:StopMovingOrSizing();
				PlaySound(1115);
			end);
			
			frame:HookScript("OnUpdate", function(__, elapsed)
				local iframe = CT_ViewportInnerFrame;
				local bframe = CT_ViewportBorderFrame;
				local screenRes = module.screenRes;

				if ( module.awaitingValues ) then
					module.awaitingValues = nil;

					CT_ViewportLeftEB.limitation = screenRes[1] / 2 - 1;
					CT_ViewportRightEB.limitation = screenRes[1] / 2 - 1;
					CT_ViewportTopEB.limitation = screenRes[2] / 2 - 1;
					CT_ViewportBottomEB.limitation = screenRes[2] / 2 - 1;
				end

				if ( module.isResizing ) then
					module.UpdateInnerFrameBounds()

					local right, left, top, bottom;

					if (ivalues[5] == 0) then
						right = 0;
						left = 0;
					else
						right = ((ivalues[2] - iframe:GetRight()) / ivalues[5]) * screenRes[1];
						left = ((iframe:GetLeft() - ivalues[1]) / ivalues[5]) * screenRes[1];
					end
					if (ivalues[6] == 0) then
						top = 0;
						bottom = 0;
					else
						top = ((ivalues[3] - iframe:GetTop()) / ivalues[6]) * screenRes[2];
						bottom = ((iframe:GetBottom() - ivalues[4]) / ivalues[6]) * screenRes[2];
					end

					if ( right < 0 ) then
						right = 0;
					end
					if ( left < 0 ) then
						left = 0;
					end
					if ( top < 0 ) then
						top = 0;
					end
					if ( bottom < 0 ) then
						bottom = 0;
					end

					CT_ViewportLeftEB:SetText(0.5*floor(left*2 + 0.1));
					CT_ViewportRightEB:SetText(0.5*floor(right*2 + 0.1));
					CT_ViewportTopEB:SetText(0.5*floor(top*2 + 0.1));
					CT_ViewportBottomEB:SetText(0.5*floor(bottom*2 + 0.1));

					module.currOffset = {
						0.5*floor(left*2 + 0.1),
						0.5*floor(right*2 + 0.1),
						0.5*floor(top*2 + 0.1),
						0.5*floor(bottom*2 + 0.1)
					};

					if ( module.elapsed ) then
						module.elapsed = module.elapsed - elapsed;
						
					else
						module.elapsed = 0.1;
					end
					if ( module.elapsed <= 0 ) then
						local value1 = (screenRes[1] - left - right);
						local value2 = (screenRes[2] - top - bottom);
						local value3
						if (value2 == 0) then
							value3 = 0;
						else
							value3 = value1 / value2;
						end
						CT_ViewportAspectRatioNewText:SetText(L["CT_Viewport/Options/AspectRatio/NewPattern"]:format(module.GetQuotient(value3)));

						local value1 = screenRes[1];
						local value2 = screenRes[2];
						local value3
						if (value2 == 0) then
							value3 = 0;
						else
							value3 = value1 / value2;
						end
						CT_ViewportAspectRatioDefaultText:SetText(L["CT_Viewport/Options/AspectRatio/DefaultPattern"]:format(module.GetQuotient(value3)));

						module.elapsed = 0.1;
					end
				else
					module.elapsed = nil;
				end
			end);
		end);
	optionsEndFrame();
	
	-- Display warning a few seconds after loading
	optionsAddObject(-25, 17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_Viewport/Options/Alerts/Heading"]);
	optionsBeginFrame(-5, 26, "checkbutton#tl:10:%y#o:CTVP_SuppressLoadingMessage#" .. L["CT_Viewport/Options/Alerts/SuppressLoadingMessageCheckButton"] .. "#l:268");
		optionsAddTooltip({L["CT_Viewport/Options/Alerts/SuppressLoadingMessageCheckButton"],L["CT_Viewport/Options/Alerts/SuppressLoadingMessageTip"] .. textColor1});
	optionsEndFrame();
	
	-- Gradient color
	optionsAddObject(-25, 17, "font#tl:5:%y#v:GameFontNormalLarge#" .. COLOR)
	optionsAddObject(-5, 10, "colorswatch#tl:10:%y#s:16:16#o:color:0,0,0,1#true")	
	
	-- see CT_Library
	return "frame#all", module:framesGetData(optionsFrameList);
end
