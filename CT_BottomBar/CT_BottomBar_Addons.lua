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

-- All of the bar frames are relative to this frame.
module.ctRelativeFrame = UIParent;

local appliedOptions;

--------------------------------------------
-- Drag Frame

local addonFrameTable;

local function addonFrame_OnEnter(self)
	local object = self.object;

	-- REMOVED CONDITIONAL IN 8.0.1.5 -- if (not appliedOptions.dragHideTooltip) then
	-- Show addon name and drag instructions.
	local text = "|c00FFFFFF" .. object.addonName .. "|r\n" .. "Left click to drag";

	-- If this frame is capable of rotation...
	if (object.rotateFunc) then
		-- Show rotation instructions.
		text = text .. "\nRight click to rotate";
	end

	-- Show reset instructions.
	text = text .. "\nShift click to reset";

	-- Show the tooltip.
	module:displayTooltip(self, text);
	-- REMOVED CONDITIONAL IN 8.0.1.5 -- end
end


local function addonFrame_OnMouseDown(self, button)
	if (button == "LeftButton") then
		if (IsShiftKeyDown()) then
			-- Reset the position of the frame.
			self.object:resetPosition();
		else
			-- Hide the tooltip while user is dragging the frame.
			if (GameTooltip:IsOwned(self)) then
				GameTooltip:Hide();
			end
			-- Start moving the frame.
			module:moveMovable(self.movable);
		end
	end
end

local function addonFrame_OnMouseUp(self, button)
	if (button == "LeftButton") then
		-- Stop moving the frame.
		module:stopMovable(self.movable);

		-- Redisplay the tooltip
		addonFrame_OnEnter(self);

	elseif (button == "RightButton") then
		-- Rotate the frame.
		self.object:rotate();
	end
end

local function addonFrame_OnLoad(self)
	self:SetBackdropBorderColor(1, 1, 1, 0);
end

local function addonDragSkeleton()
	if ( not addonFrameTable ) then
		addonFrameTable = {
			-- The drag button.
			["button#hidden#i:button#st:LOW"] = {
				"backdrop#tooltip#0:0:0:0.75",
				"font#v:GameFontNormalLarge#i:text",
				["onload"] = addonFrame_OnLoad,
				["onenter"] = addonFrame_OnEnter,
				["onmousedown"] = addonFrame_OnMouseDown,
				["onmouseup"] = addonFrame_OnMouseUp,
			}
		};
	end
	return "frame#s:30:1", addonFrameTable;
end

--------------------------------------------
-- Addon (bar) object

local addon = {};
local addonMeta = {__index = addon};

-- List of addons
local addons = {};
module.addons = addons;

function addon:isDefaultHidden()
	-- Should this bar be hidden by default?

	local settings = self.settings;

	if (settings) then
		if (settings.perClass ) then
			local _, class = UnitClass("player");

			-- If class isn't listed then hide the bar (unless we detect a shapeshift form)...
			if ( not settings.perClass[class] ) then

				-- Don't hide it if we detect a shapeshift form
				if ( GetNumShapeshiftForms() > 0 ) then
					-- Not hidden
					return false;
				end

				-- It should be hidden
				return true;
			end
		end
	end

	-- Not hidden
	return false;
end

function addon:setClamped(clamp)
	-- Set clamped state of the frame
	if (self.frame) then
		self.frame:SetClampedToScreen(clamp);
	end
end

function addon:rotate()
	-- Change the orientation of the bar.
	--
	-- The bar can be either horizontal (left to right),
	-- or vertical (top to bottom).
	--
	if ( not self.rotateFunc ) then
		return;
	end
	if ( InCombatLockdown() and self.frame:IsProtected() ) then
		return;
	end
	local newOrientation = "ACROSS";
	if ( self.orientation == "ACROSS" ) then
		self.orientation = "DOWN";
		newOrientation = "DOWN";
	else
		self.orientation = "ACROSS";
	end

	local optName = "orientation" .. self.optionName;
	module:setOption(optName, newOrientation);
	appliedOptions[optName] = newOrientation;

--	self:rotateFunc(newOrientation);
	self:update();
end

function addon:position()
	-- Position the bar on the screen.
	--
	local frame = self.frames;
	if ( not frame[0] ) then
		frame = frame[1];
	end
	if ( InCombatLockdown() and frame:IsProtected() ) then
		return;
	end
	frame:ClearAllPoints();
	frame:SetPoint("BOTTOMLEFT", self.frame);
end

function addon:resetPosition()
	-- Reset the position of the bar to a default position.
	--
	if ( InCombatLockdown() and self.frame:IsProtected() ) then
		return;
	end

	local defaults = self.defaults;
	local frame = self.frame;

	local yoffset = (defaults[5] or 0);
	if (TitanMovable_GetPanelYOffset and TITAN_PANEL_PLACE_BOTTOM and TitanPanelGetVar) then
		yoffset = yoffset + (tonumber( TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM, TitanPanelGetVar("BothBars")) ) or 0);
	end

	frame:ClearAllPoints();
	frame:SetPoint(defaults[1], UIParent, defaults[3], defaults[4], yoffset);

	if ( self.rotateFunc ) then
		local newOrientation = "ACROSS";
		self.orientation = newOrientation;

		local optName = "orientation" .. self.optionName;
		module:setOption(optName, newOrientation);
		appliedOptions[optName] = newOrientation;

--		self:rotateFunc(newOrientation);
		self:update();
	end

	module:stopMovable(self.optionName);
end

function addon:update()
	-- Update the bar

	if (not self.isDisabled) then
		if (self.updateFunc) then
			self.updateFunc(self);
		end
	end

	local button = self.frame.button;
	if ( button ) then
		local orientation = self.orientation;
		local text = button.text;
		
		-- Change the name displayed with the bar when the options window is open.
		text:ClearAllPoints();
		if ( orientation == "ACROSS" ) then
			text:SetText(self.acrossName);
			text:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 10, -11);
		else
			text:SetText(self.downName);
			text:SetPoint("BOTTOM", button, "TOP", 0, -11);
		end
	end
end

function addon:init()
	-- Initialize the bar.

	local frames = self.frames;	
	local optionName = self.optionName;

	if ( frames ) then
		local frame = self.frame;
		local button = frame.button;

		-- Change the parent of the drag button to UIParent so that
		-- it won't get hidden if the self.frame is hidden. We would
		-- like to be able to see the drag frame when the options window
		-- is open, even if the buttons on it are hidden.
		button:SetParent(UIParent);
		button:SetFrameLevel(self.frame:GetFrameLevel());

		if ( not self.skipDefaultPosition ) then
			self:position();
		end
		
		local defaults = self.defaults;
		if ( defaults ) then
			frame:ClearAllPoints();
			frame:SetPoint(unpack(defaults));
		end
		
		button.object = self;
		button.movable = optionName;

		-- Existing users (CT_BottomBar 3.003 and earlier) have drag
		-- frames relative to MainMenuBar or MainMenuBarArtFrame.
		--
		-- This changes the relative frame to UIParent to match what
		-- CT_BottomBar 3.004 is using. This avoids problems when
		-- entering a vehicle. Unlike MainMenuBar, UIParent does not
		-- move when you enter a vehicle.
		--
		-- Being relative to the bottom of MainMenuBar causes problems
		-- when you enter a vehicle and Blizzard moves MainMenuBar -130
		-- units below the bottom of UIParent. If the user wanted to
		-- show the bars while in a vehicle, then most of them would
		-- shift down and not be visible when Blizzard repositioned
		-- MainMenuBar.
		local movName = "MOVABLE-" .. optionName;
		local movOpt = module:getOption(movName);
		if (movOpt and (movOpt[2] == "MainMenuBar" or movOpt[2] == "MainMenuBarArtFrame")) then
			movOpt[2] = "UIParent";
			module:setOption(movName, movOpt);
		end

		-- Register the drag frame as movable (also repositions
		-- the frame if it was previously moved by the user).
		local clamp = appliedOptions.clampFrames;

		module:registerMovable(optionName, frame, clamp);

		-- The main frame is the one who's position is saved when the bar is moved.
		-- One button will be anchored to the main frame, the rest will be anchored to each other.
		-- The buttons are parented to the main frame.
		-- The guide frame will be anchored to the addon's buttons in the addon's update/orientation routine.
		-- The guide frame is parented to the main frame.
		-- The bar's drag button is anchored to the corners of the guide frame.
		-- The bar's drag button is parented to UIParent.

		-- Anchor the drag button to the guide frame.
		local guideFrame;
		if ( frames[0] ) then
			guideFrame = frames;
		else
			guideFrame = frames[1];
		end
		button:ClearAllPoints();
		button:SetPoint("TOPLEFT", guideFrame, -11, 11);
		button:SetPoint("BOTTOMRIGHT", guideFrame, 11, -11);
	end

	if (self.isDisabled) then
		return;
	else
		self:enable();
	end
end

function addon:config()
	-- Perform additional configuration after intialization has finished.
	if (self.configFunc) then
		self.configFunc(self);
	end
end

function addon:disable()
	self.isDisabled = true;
	self.disabledVisibility = false;

	-- Restore the frames to their original state.
	self:loadData();

	if (self.disableFunc) then
		self.disableFunc(self);
	end

	self.helperFrame:ClearAllPoints();

	self:updateDragVisibility(false);
	self:updateVisibility();
end

function addon:enable()
	local frames = self.frames;	
	local frame = self.frame;
	local optionName = self.optionName;
	local settings = self.settings or {};

	if (frames) then
		local guideFrame;
		if ( frames[0] ) then
			guideFrame = frames;
			frames:SetParent(frame);
		else
			for key, value in ipairs(frames) do
				value:SetParent(frame);
			end
			guideFrame = frames[1];
		end
		
	end
	
	local defaultOrientation = (settings.orientation or "ACROSS");
	local orientation = appliedOptions["orientation" .. optionName] or defaultOrientation;
	self.orientation = orientation;

	self.isDisabled = false;
	self.disabledVisibility = false;

	if (self.enableFunc) then
		self.enableFunc(self);
	end

	if (self.updateFunc) then
		self.updateFunc(self);
	end

	self:update();
	self:setClamped(appliedOptions.clampFrames);
	self:updateVisibility();
end

function addon:saveFrames()
	-- Save data about the frames.
	self.savedFrames = {};

	local save;
	local frame;
	local frames = self.frames;
	local ancP, relF, relP, xOff, yOff, p;
	if (frames) then
		for i = 2, #frames do
			frame = frames[i];

			save = {};
			save.frame = frame;
			save.parent = frame:GetParent();
			save.alpha = frame:GetAlpha();
			if (self.settings.saveShown) then
				save.shown = frame:IsShown();
			end
			if (frame:GetObjectType() ~= "FontString") then
				save.mouse = frame:IsMouseEnabled();
				save.clamped = frame:IsClampedToScreen();
				save.height = frame:GetHeight();
				save.width = frame:GetWidth();
				save.scale = frame:GetScale();
			end
			save.points = {};
			p = 1;
			ancP, relF, relP, xOff, yOff = frame:GetPoint(p);
			while (ancP) do
				save.points[p] = {ancP, relF, relP, xOff, yOff};
				p = p + 1;
				ancP, relF, relP, xOff, yOff = frame:GetPoint(p);
			end

			self.savedFrames[i-1] = save;
		end
	end
end

function addon:saveTextures()
	-- Save data about the textures.
	self.savedTextures = {};

	local save;
	local frame;
	local frames = self.textures;
	local r, g, b, a;
	if (frames) then
		for i = 1, #frames do
			frame = frames[i];

			save = {};
			save.frame = frame;
			save.shown = frame:IsShown();
			r, g, b, a = frame:GetVertexColor();
			save.vertexColor = { r, g, b, a };

			self.savedTextures[i] = save;
		end
	end
end

function addon:saveData()
	-- This should only be called when we know that all of the frames
	-- and textures are in their default UI state.

	-- Save data about the frames.
	self:saveFrames();

	-- Save data about the textures.
	self:saveTextures();
end

function addon:loadFrames()
	-- Restore frames using the saved info.
	local save;
	local frame;
	local ancP, relF, relP, xOff, yOff;
	local frames = self.savedFrames;
	if (frames) then
		for i, save in ipairs(frames) do
			frame = save.frame;
			frame:ClearAllPoints();
		end
		for i, save in ipairs(frames) do
			frame = save.frame;
			frame:SetParent(save.parent);
			frame:SetAlpha(save.alpha);
			if (frame:GetObjectType() ~= "FontString") then
				frame:EnableMouse(save.mouse);
				frame:SetClampedToScreen(save.clamped);
				frame:SetHeight(save.height);
				frame:SetWidth(save.width);
				frame:SetScale(save.scale);
			end
			for p = 1, #save.points do
				frame:SetPoint( unpack(save.points[p]) );
			end
			if (self.settings.saveShown) then
				if (save.shown) then
					frame:Show();
				else
					frame:Hide();
				end
			end
		end
	end
end

function addon:loadTextures()
	-- Restore textures using the saved info.
	local save;
	local frame;
	local r, g, b, a;
	local frames = self.savedTextures;
	if (frames) then
		for i, save in ipairs(frames) do
			frame = save.frame;
			if (save.shown) then
				frame:Show();
			else
				frame:Hide();
			end
			frame:SetVertexColor( unpack(save.vertexColor) );
		end
	end
end

function addon:loadData()
	-- Restore the frames to their saved state.
	self:loadFrames();

	-- Restore the textures to their saved state.
	self:loadTextures();
end

function addon:updateTextureVisibility(show)
	-- Show or hide textures associated with this bar.
	-- show == true: Show the textures.
	--         false, nil: Hide the textures.

	-- Get function used to show or hide a texture.
	local func;
	if (show) then
		func = MinimapBorder.Show;
	else
		func = MinimapBorder.Hide;
	end

	-- List of textures associated with this bar.
	local textureList = self["textures"];

	-- Show or hide the textures
	if (type(textureList) == "table") then
		for i, texture in ipairs(textureList) do
			func(texture);
		end
	elseif (textureList) then
		-- Only one texture to show/hide.
		func(textureList);
	end
end

function addon:updateDragVisibility(show)
	-- Show or hide the drag frame for this bar.
	-- show == nil: Determine if drag frame should be shown or hidden.
	--         true: Show the drag frame.
	--         false: Hide the drag frame.
	if (show == nil) then
		-- Determine if the drag frame should be shown or hidden.
		if (self.isDisabled) then
			-- Bar is disabled, so don't show the drag frame.
			show = false;
		elseif (not module.optionsWindowOpen) then
			-- The options window is not open, so don't show the drag frame.
			show = false;
		else
			-- The bar is enabled.
			-- The options window is open.
			show = false;
			local hasSpecialUI;
			local usedOnSpecialUI;
			local hideSpecialUI;
			if (module:hasPetBattleUI()) then
				hasSpecialUI = true;
				usedOnSpecialUI = self.settings.usedOnPetBattleUI;
				hideSpecialUI = appliedOptions.petbattleHideFrame;
			elseif (module:hasVehicleUI()) then
				hasSpecialUI = true;
				usedOnSpecialUI = self.settings.usedOnVehicleUI;
				hideSpecialUI = appliedOptions.vehicleHideFrame;
			elseif (module:hasOverrideUI()) then
				hasSpecialUI = true;
				usedOnSpecialUI = self.settings.usedOnOverrideUI;
				hideSpecialUI = appliedOptions.overrideHideFrame;
			else
				-- Player does not have a special UI,
				-- so we can show the drag frame for this bar.
				hasSpecialUI = false;
				show = true;
			end
			if (hasSpecialUI) then
				-- Player has a special UI.
				if (usedOnSpecialUI) then
					-- This bar is used on the special UI.
					if (hideSpecialUI) then
						-- Since the player wants to hide the special UI,
						-- we can show the drag frame for this bar.
						show = true;
					end
				else
					-- This bar is not used on the special UI,
					-- so we can show the drag frame for this bar.
					show = true;
				end
			end
		end
	end
	if (show) then
		-- Show the drag frame for this bar.
		self.frame.button:Show();
	else
		-- Hide the drag frame for this bar.
		self.frame.button:Hide();
	end
end

function addon:updateVisibility()
	-- Show or hide the bar.
	-- This shows/hides the frame that we have the buttons parented do, which
	-- in turn causes the buttons to become shown/hidden.
	local frame = self.frame;
	local protected = frame:IsProtected();

	if (self.isDisabled) then
		-- The bar is disabled.
		if (not self.disabledVisibility) then
			-- We have not set the visibility of this disabled bar yet.
			if (protected) then
				if (not InCombatLockdown()) then
					UnregisterStateDriver(frame, "visibility");
					frame:Show();
					self.disabledVisibility = true;
				end
			else
				frame:Show();
				self.disabledVisibility = true;
			end
			if (self.settings.updateVisibility) then
				self.settings.updateVisibility();
			end
		end
		-- Hide the bar's drag frame.
		self:updateDragVisibility(false);
		return;
	end

	--  The bar is not disabled.

	-- Does the player want this frame to be hidden?
	local generalHide = appliedOptions[self.optionName];
	-- If this frame should always be hidden, then override the player's choice.
	if (frame.forceHide) then
		generalHide = 1;
	end

	if (protected) then
		-- -----
		-- Since it is a protected frame, we're going to use a secure state driver
		-- to control the visibility of the frame.
		-- -----
		if (not InCombatLockdown()) then
			-- Determine what condition string we'll use for the state driver.
			local cond = "";
			if (generalHide) then
				-- Hide the bar.
				cond = "hide";
			else
				if (frame.RequiresPetToShow) then
					cond = cond .. "[@pet,noexists]hide; ";
				end				
				if (appliedOptions.petbattleHideEnabledBars) then
					-- Player does not want to show the bar when there is a pet battle UI.
					cond = cond .. "[petbattle]hide; ";
				else
					cond = cond .. "[petbattle]show; ";
				end
				if (appliedOptions.vehicleHideEnabledBars) then
					-- Player does not want to show the bar when there is a vehicle UI.
					cond = cond .. "[vehicleui]hide; ";
				else
					cond = cond .. "[vehicleui]show; ";
				end
				if (appliedOptions.overrideHideEnabledBars) then
					-- Player does not want to show the bar when there is an override UI.
					cond = cond .. "[overridebar]hide; ";
				else
					cond = cond .. "[overridebar]show; ";
				end
				-- If none of the above conditions are true, then show the bar.
				cond = cond .. "show";
			end
			RegisterStateDriver(frame, "visibility", cond);
		end
	else
		-- -----
		-- Since the frame is not protected, we're going to be
		-- using :Show() and :Hide() to control visibility.
		-- -----

		-- local inVehicle = UnitHasVehicleUI("player");
		-- local inVehicle = HasVehicleActionBar() -- UnitHasVehicleUI("player");
		local hasSpecialUI;
		local hideEnabledBars;
		local hideSpecialUI;
		local showOnSpecialUI;
		if module:hasPetBattleUI() then
			hasSpecialUI = true;
			hideEnabledBars = appliedOptions.petbattleHideEnabledBars;
			hideSpecialUI = appliedOptions.petbattleHideFrame;
			showOnSpecialUI = self.settings.showOnPetBattleUI;
		elseif (module:hasVehicleUI()) then
			hasSpecialUI = true;
			hideEnabledBars = appliedOptions.vehicleHideEnabledBars;
			hideSpecialUI = appliedOptions.vehicleHideFrame;
			showOnSpecialUI = self.settings.showOnVehicleUI;
		elseif (module:hasOverrideUI()) then
			hasSpecialUI = true;
			hideEnabledBars = appliedOptions.overrideHideEnabledBars;
			hideSpecialUI = appliedOptions.overrideHideFrame;
			showOnSpecialUI = self.settings.showOnOverrideUI;
		end
		if (not hasSpecialUI or (hasSpecialUI and not hideEnabledBars)) then
			-- -----
			-- Player does not have a special UI, OR
			-- Player has a special UI and they don't want to hide the other bars when they have a special UI.
			-- -----
			-- Show the bar unless we need to hide it.
			if (generalHide) then
				frame:Hide();
			else
				frame:Show();
			end
		else
			-- -----
			-- Player has a special UI and they want to hide the bars when they have a special UI.
			-- -----
			if (showOnSpecialUI) then
				-- This bar contains items shown on the special UI.
				if (hideSpecialUI) then
					-- Player wants to hide the special UI,
					-- so hide the bar also.
					frame:Hide();
				else
					-- Player does not want to hide the special UI.
					-- Show the bar unless we need to hide it.
					if (generalHide) then
						frame:Hide();
					else
						frame:Show();
					end
				end
			else
				-- This bar does not contain items shown on the special UI.
				-- Hide the bar.
				frame:Hide();
			end
		end
	end

	if (not self.isDisabled) then
		if (self.settings.updateVisibility) then
			self.settings.updateVisibility();
		end
	end

	-- Show or hide the bar's drag frame.
	self:updateDragVisibility(nil);
end

--------------------------------------------
-- Visibility

function module:updateBarVisibility()
	-- Update the visibility of each of the bars.
	for key, obj in ipairs(addons) do
		obj:updateVisibility();
	end
end

function module:updateSpecialVisibility()
	-- Update the visibility of the special UI frames.
	if (not appliedOptions) then
		return;
	end

	-- Update the visibility of the Override UI frame.
	-- The vehicle UI and override UI use the same special UI frame.
	local updatedOverride = false;
	if (appliedOptions.vehicleHideFrame or appliedOptions.overrideHideFrame) then
		-- We want to hide the override UI frame.
		if (module:hideOverrideActionBar()) then
			updatedOverride = true;
		end
	else
		-- We do not want to hide the override UI frame.
		if (module:showOverrideActionBar()) then
			updatedOverride = true;
		end
	end

	-- Update the visibility of the Pet Battle UI frame.
	local updatedPetBattle = false;
	if (appliedOptions.petbattleHideFrame) then
		-- We want to hide the pet battle UI frame.
		-- (Currently we are not attempting to hide the pet battle UI frame).
		updatedPetBattle = false;
	else
		-- We do not want to hide the pet battle UI frame.
		-- (Currently we are not attempting to show the pet battle UI frame).
		updatedPetBattle = true;
	end

	if (updatedOverride or updatedPetBattle) then
		-- We want to update bars that share items with these special UIs.
		-- For example: menu micro buttons, experience bar, vehicle aim up/down buttons,
		-- and the vehicle exit button.
		-- When the special UI is visible, these items will be on the special UI's frame.
		-- When the special UI is not visible, these items will be where the user placed them.
		local func;
		local update;
		for i, obj in ipairs(addons) do
			if (not obj.isDisabled) then
				-- The bar is not disabled.
				if (updatedOverride and (obj.settings.usedOnVehicleUI or obj.settings.usedOnOverrideUI)) then
					update = true;
				elseif (updatedPetBattle and (obj.settings.usedOnPetBattleUI)) then
					update = true;
				else
					update = false;
				end
				if (update) then
					-- The bar is used on the special UI.
					func = obj.updateFunc;
					if (func) then
						-- Call the bar's update function.
						func(obj);
					end
				end
			end
		end
	end
end

function module:updateAllVisibility()
	-- Update visiblity if bars and special UI frames.

	-- Update the visibility of the bars.
	-- Need to call updateBarVisibility() before updateSpecialVisibility()
	-- otherwise cannot drag menu bar and vehicle tools bar when in a vehicle,
	-- with the vehicle frame and ct_bottombar bars hidden.
	module:updateBarVisibility();

	-- Update the visibility of the special UI frames.
	-- This may also update some bars.
	module:updateSpecialVisibility();
end

--------------------------------------------
-- Addon Registrar

function module:loadAddon(name)
	-- Load an addon
	local func = self.loadedAddons[name];
	if (func) then
		self.loadedAddons[name] = nil;
		-- Call the registration function.
		func();
	end
end

function module:registerAddon(
	optionName, frameName, addonName, acrossName, downName, 
	defaults, settings,
	initFunc, postInitFunc, configFunc,
	updateFunc, rotateFunc,
	enableFunc, disableFunc,
	...)

	-- Register an addon
	local new = {};
	setmetatable(new, addonMeta);
	tinsert(addons, new);

	new.optionName = optionName;  -- Name used in option names
	new.frameName = (frameName or optionName);  -- Name used in frame names.
	new.addonName = (addonName or optionName);  -- Name shown in options window and tooltip.
	new.acrossName = (acrossName or optionName);  -- Name shown above bar when in 'across' orientation.
	new.downName = (downName or optionName);  -- Name shown above bar when in 'down' orientation.
	new.defaults = defaults;
	new.settings = settings or {};
	new.configFunc = configFunc;
	new.rotateFunc = rotateFunc;
	new.updateFunc = updateFunc;
	new.enableFunc = enableFunc;
	new.disableFunc = disableFunc;

	-- Store our frames & textures
	local index = 1;

	if ( ( (select(index, ...)) or "" ) ~= "" ) then
		-- Add a frame with a drag button only if we have frame
		local frame = module:getFrame(addonDragSkeleton, nil, "CT_BottomBar_" .. new.frameName .. "_Frame");
		new.frame = frame;
	end

	if (initFunc) then
		-- Run this before assembling the list of frames.
		-- The init function may create some that will be referenced in the list.
		new.skipDefaultPosition = initFunc(new);
	end

	local key = "frames";
	local value;
	for i = index, select('#', ...), 1 do
		value = select(i, ...);

		if ( value == "" ) then
			-- Constitutes change to textures
			key = "textures";
		else
			if ( type(value) == "string" ) then
				value = new[value];
			end
			
			-- Add our value
			if ( not new[key] ) then
				new[key] = value;
			elseif ( new[key][0] ) then
				new[key] = { new[key], value };
			else
				tinsert(new[key], value);
			end
		end
	end

	-- Save data about the frames in their original state.
	new:saveData();

	if (postInitFunc) then
		-- Run this after assembling the list of frames.
		postInitFunc(new);
	end

--	if (updateFunc) then
--		updateFunc(new);
--	end

	return new;
end

function module:addonsInit()
	-- Initialize this lua file.
	appliedOptions = module.appliedOptions;
end
