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

if CT_BottomBar:getGameVersion() >= 10 then
	return
end

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

--------------------------------------------
-- Extra Action Bar

local numExtraButtons = 1;  -- Number of buttons on the bar

local function addon_UpdateOrientation(self, orientation)
	-- Update the orientation of the frame.
	-- self == extra bar object
	-- orientation == "ACROSS"

	if (InCombatLockdown()) then
		return;
	end

	orientation = orientation or "ACROSS";

	-- ExtraActionBarFrame:ClearAllPoints();
	-- ExtraActionBarFrame:SetPoint("BOTTOMLEFT", self.frame);

	ExtraActionButton1:ClearAllPoints();
	ExtraActionButton1:SetPoint("BOTTOMLEFT", self.frame);

	local obj;
	for i = 2, numExtraButtons do
		obj = _G["ExtraActionButton" .. i];
		obj:ClearAllPoints();
		if ( orientation == "ACROSS" ) then
			obj:SetPoint("LEFT", _G["ExtraActionButton" .. (i-1)], "RIGHT", spacing, 0);
		else
			obj:SetPoint("TOP", _G["ExtraActionButton" .. (i-1)], "BOTTOM", 0, -spacing);
		end
	end
end

local function addon_HideButtonTexture(self, value)
	-- Hide or show button style texture.
	-- Blizzard's ExtraActionBar_OnShow() in ExtraActionBar.lua sets the actual texture.
	if (self.style) then
		if (value) then
			self.style:Hide();
		else
			self.style:Show();
		end
	end
end

local function addon_Update(self)
	-- Update the frame
	-- self == extra bar object

	if (not InCombatLockdown()) then
		ExtraActionBarFrame:EnableMouse(false);

		-- Anchor the whole bar to ours so that we can move the extra bar,
		-- but not show/hide it. We'll let Blizzard show and hide the extra bar
		-- when needed.

		local obj1, obj2;

		-- obj1 = ExtraActionBarFrame;
		-- obj2 = ExtraActionBarFrame;

		obj1 = ExtraActionButton1;
		obj2 = _G["ExtraActionButton" .. numExtraButtons];

		self.helperFrame:ClearAllPoints();
		self.helperFrame:SetPoint("TOPLEFT", obj1);
		self.helperFrame:SetPoint("BOTTOMRIGHT", obj2);

		addon_UpdateOrientation(self, self.orientation);

		module:update("extraBarScale", appliedOptions.extraBarScale);
	end

	module:update("extraBarTexture", appliedOptions.extraBarTexture);
end

local function addon_ApplyOption(optName, value)

	local self = module.ctExtraBar;

	if (self.isDisabled) then
		return;
	end

	local func;

	if (optName == "extraBarTexture") then
		-- Can be done while in combat.
		func = addon_HideButtonTexture;

	elseif (optName == "extraBarScale") then
		-- Must not be in combat.
		if (InCombatLockdown()) then
			return;
		end

		-- ExtraActionBarFrame:SetScale(value);

		for i = 1, numExtraButtons do
			_G["ExtraActionButton" .. i]:SetScale(value);
		end

		return;

	end

	if (func) then
		for i = 1, numExtraButtons do
			func(_G["ExtraActionButton" .. i], value);
		end
	end
end

local function addon_Enable(self)
	local frame = self.helperFrame;

	-- We shouldn't be in combat when enabling the addon,
	-- but just to be safe...
	if (not InCombatLockdown()) then
		for i = 1, numExtraButtons do
			local button = _G["ExtraActionButton" .. i];
			-- Change the button's parent to be the ExtraActionBarFrame.
			-- This ensures the button will be visible when Blizzard shows
			-- the bar frame, and hidden when they hide it.
			button:SetParent(ExtraActionBarFrame);
		end
		-- Blizzard's bar frame is mouse enabled, so disable the mouse.
		ExtraActionBarFrame:EnableMouse(false);
	end
end

local function addon_Disable(self)
	local frame = self.helperFrame;

	-- ExtraActionBarFrame:ClearAllPoints();
	-- ExtraActionBarFrame:SetPoint("BOTTOM", MainMenuBar, 0, 160);
	-- ExtraActionBarFrame:SetScale(1);

	-- We shouldn't be in combat when disabling the addon,
	-- but just to be safe...
	if (not InCombatLockdown()) then
		-- Re-enable the mouse for Blizzard's bar frame.
		ExtraActionBarFrame:EnableMouse(true);
	end

	for i = 1, numExtraButtons do
		local button = _G["ExtraActionButton" .. i];
		-- Make sure the button style textures are visible.
		addon_HideButtonTexture(button, false);
	end
end

local function addon_Config(self)
	-- Perform a one time configuration after bar has been initialized by addon:init().
	if (not self.isDisabled) then
		module.updateExtraBar("extraBarTexture", appliedOptions.extraBarTexture);
		module.updateExtraBar("extraBarScale", appliedOptions.extraBarScale);
	end
end

local function addon_Init(self)
	-- Initialization
	-- self == extra bar object

	appliedOptions = module.appliedOptions;

	module.ctExtraBar = self;
	module.updateExtraBar = addon_ApplyOption;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Extra Bar",  -- option name
		"ExtraBar",  -- used in frame names
		"Extra Bar",  -- shown in options window & tooltips
		"Extra Bar",  -- title for horizontal orientation
		"Extra",  -- title for vertical orientation
		{ "BOTTOM", ctRelativeFrame, "BOTTOM", 0, 160 },
		{ -- settings
			orientation = "ACROSS",
			saveShown = false,  -- don't save shown state... let Blizzard show/hide it.
			noHideOption = true,  -- no "hide" option for this bar
		},
		addon_Init,
		nil,  -- no post init function
		addon_Config,
		addon_Update,
		nil,  -- no orientation function -- addon_UpdateOrientation,
		addon_Enable,
		addon_Disable,
		"helperFrame",
		-- List the ExtraActionButton's here so we can take advantage of
		-- the saving of their properties by CT_BottomBar_Addons.lua.
		-- This will also parent them to our frame, but we'll reparent them
		-- to Blizzard's frame so that they will hide/show when Blizzard's
		-- ExtraActionBarFrame hides/shows.
		ExtraActionButton1
	);
end

module.loadedAddons["Extra Bar"] = addon_Register;

-------------------------

-- This lets us simulate what happens when the game
-- needs to show the extra action bar.
-- To force the bar to show:
-- 	/run CT_BottomBar_ShowExtraBar(true)
-- To force the bar to hide:
-- 	/run CT_BottomBar_ShowExtraBar(false)
-- NOTE: This will cause taint, so only use it for
-- testing purposes. Reload the UI to return to
-- the original state.
do
	local function vargHandler(event, ...)
		local frame, script;
		for i = 1, select("#", ...) do
			frame = select(i, ...);
			script = frame:GetScript("OnEvent");
			if (script) then
				script(frame, event);
			end
		end
	end
	local function sendEvent(event)
		vargHandler(event, GetFramesRegisteredForEvent(event));
	end

	local showExtra = false;
	local hasExtraActionBar = function() return showExtra; end

	function CT_BottomBar_ShowExtraBar(show)
		showExtra = (show ~= false);
		-- Show the button
		-- Note: We didn't have to show the button in WoW 4.
		-- In WoW 5 the button seems to be hidden by default.
		if (not InCombatLockdown()) then
			ExtraActionButton1:Show();
		end
		-- Replace the HasExtraActionBar() function with our own.
		HasExtraActionBar = hasExtraActionBar;
		-- Send the UPDATE_EXTRA_ACTIONBAR event to all frames
		-- that have registered for it.
		sendEvent("UPDATE_EXTRA_ACTIONBAR");
	end
end

-- CT_BottomBar_ShowExtraBar(true)

-------------------------
